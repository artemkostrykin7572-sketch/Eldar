from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class WeatherRecordRead(BaseModel):
    id: UUID
    city: str
    forecast_date: date
    temperature: float
    pressure: float      # mmHg
    humidity: float
    wind_speed: float
    kp_index: float
    temp_delta: float
    pressure_delta: float
    fetched_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class ForecastRequest(BaseModel):
    city: str = Field(..., min_length=1, max_length=100)
    days: int = Field(5, ge=1, le=10)
