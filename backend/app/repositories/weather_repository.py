from datetime import date

from advanced_alchemy.repository import SQLAlchemyAsyncRepository
from sqlalchemy import select

from app.models.weather import WeatherRecord


class WeatherRepository(SQLAlchemyAsyncRepository[WeatherRecord]):
    model_type = WeatherRecord

    async def get_by_city_and_date(self, city: str, forecast_date: date) -> WeatherRecord | None:
        stmt = select(WeatherRecord).where(
            WeatherRecord.city == city,
            WeatherRecord.forecast_date == forecast_date,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_forecast(self, city: str, days: int = 5) -> list[WeatherRecord]:
        """Return the next `days` weather records for a city ordered by date."""
        stmt = (
            select(WeatherRecord)
            .where(WeatherRecord.city == city)
            .order_by(WeatherRecord.forecast_date)
            .limit(days)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())
