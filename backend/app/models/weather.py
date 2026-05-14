from datetime import date, datetime

from advanced_alchemy.base import UUIDAuditBase
from sqlalchemy import Date, DateTime, Float, Index, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column


class WeatherRecord(UUIDAuditBase):
    """Погода в конкретный день в конкретном городе."""

    __tablename__ = "weather_records"
    __table_args__ = (
        UniqueConstraint("city", "forecast_date", name="uq_weather_city_date"),
        Index("ix_weather_city_date", "city", "forecast_date"),
    )

    city: Mapped[str] = mapped_column(String(100))
    forecast_date: Mapped[date] = mapped_column(Date)

    temperature: Mapped[float] = mapped_column(Float)
    pressure: Mapped[float] = mapped_column(Float)
    humidity: Mapped[float] = mapped_column(Float)
    wind_speed: Mapped[float] = mapped_column(Float)
    kp_index: Mapped[float] = mapped_column(Float)

    temp_delta: Mapped[float] = mapped_column(Float, default=0.0)
    pressure_delta: Mapped[float] = mapped_column(Float, default=0.0)

    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
