"""
Fetches weather and geomagnetic data from external APIs and persists them.

External APIs (no API keys required):
  - Open-Meteo geocoding  → city coordinates
  - Open-Meteo forecast   → temperature, pressure, humidity, wind
  - NOAA SWPC             → planetary Kp index
"""

from datetime import UTC, date, datetime, timedelta

import httpx

from app.models.weather import WeatherRecord
from app.repositories.weather_repository import WeatherRepository


_KP_URL = "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json"
_GEO_URL = "https://geocoding-api.open-meteo.com/v1/search"
_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

HPA_TO_MMHG = 0.750061683


class WeatherService:
    def __init__(self, repo: WeatherRepository) -> None:
        self._repo = repo

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def fetch_and_store(self, city: str, days: int = 5) -> list[WeatherRecord]:
        """Fetch forecast from external APIs, upsert into DB, return records."""
        coords = await self._geocode(city)
        raw_forecast = await self._fetch_forecast(*coords, days=days)
        kp_index = await self._fetch_kp_index()

        now = datetime.now(UTC)
        records: list[WeatherRecord] = []

        for i, row in enumerate(raw_forecast):
            existing = await self._repo.get_by_city_and_date(city, row["date"])
            pressure_delta = row["pressure"] - raw_forecast[i - 1]["pressure"] if i > 0 else 0.0
            temp_delta = row["temp"] - raw_forecast[i - 1]["temp"] if i > 0 else 0.0

            if existing:
                existing.temperature = row["temp"]
                existing.pressure = row["pressure"]
                existing.humidity = row["humidity"]
                existing.wind_speed = row["wind_speed"]
                existing.kp_index = kp_index
                existing.temp_delta = temp_delta
                existing.pressure_delta = pressure_delta
                existing.fetched_at = now
                record = await self._repo.update(existing)
            else:
                record = await self._repo.add(
                    WeatherRecord(
                        city=city,
                        forecast_date=row["date"],
                        temperature=row["temp"],
                        pressure=row["pressure"],
                        humidity=row["humidity"],
                        wind_speed=row["wind_speed"],
                        kp_index=kp_index,
                        temp_delta=temp_delta,
                        pressure_delta=pressure_delta,
                        fetched_at=now,
                    )
                )
            records.append(record)

        return records

    async def get_forecast(self, city: str, days: int = 5) -> list[WeatherRecord]:
        """Return cached records, refreshing if today's data is stale."""
        records = await self._repo.get_forecast(city, days)
        today = date.today()
        has_today = any(r.forecast_date == today for r in records)

        if not has_today or not records:
            records = await self.fetch_and_store(city, days)

        return records

    # ------------------------------------------------------------------
    # External API calls
    # ------------------------------------------------------------------

    async def _geocode(self, city: str) -> tuple[float, float]:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(_GEO_URL, params={"name": city, "count": 1, "language": "ru"})
            resp.raise_for_status()
            data = resp.json()

        results = data.get("results", [])
        if not results:
            raise ValueError(f"Город не найден: {city}")

        return results[0]["latitude"], results[0]["longitude"]

    async def _fetch_forecast(
        self, lat: float, lon: float, *, days: int
    ) -> list[dict]:
        params = {
            "latitude": lat,
            "longitude": lon,
            "daily": "temperature_2m_max,temperature_2m_min,surface_pressure_mean,relative_humidity_2m_mean,wind_speed_10m_max",
            "forecast_days": days,
            "timezone": "auto",
        }
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(_FORECAST_URL, params=params)
            resp.raise_for_status()
            data = resp.json()

        daily = data["daily"]
        rows = []
        for i, iso_date in enumerate(daily["time"]):
            t_max = daily["temperature_2m_max"][i] or 0.0
            t_min = daily["temperature_2m_min"][i] or 0.0
            rows.append(
                {
                    "date": date.fromisoformat(iso_date),
                    "temp": round((t_max + t_min) / 2, 1),
                    "pressure": round((daily["surface_pressure_mean"][i] or 1013) * HPA_TO_MMHG, 1),
                    "humidity": round(daily["relative_humidity_2m_mean"][i] or 60, 1),
                    "wind_speed": round(daily["wind_speed_10m_max"][i] or 0, 1),
                }
            )
        return rows

    async def _fetch_kp_index(self) -> float:
        try:
            async with httpx.AsyncClient(timeout=8) as client:
                resp = await client.get(_KP_URL)
                resp.raise_for_status()
                data = resp.json()

            # data[0] is header row; skip it, take the last entry's Kp value
            entries = [row for row in data[1:] if row and len(row) >= 2]
            if entries:
                return float(entries[-1][1])
        except Exception:
            pass
        return 2.0  # fallback: calm geomagnetic activity
