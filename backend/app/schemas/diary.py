from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class DiaryEntryCreate(BaseModel):
    entry_date: date
    wellbeing_rating: int = Field(..., ge=1, le=10)
    symptoms: list[str] = Field(default_factory=list)
    comment: str | None = Field(None, max_length=2000)
    weather_pressure: float | None = None
    weather_kp_index: float | None = None
    risk_level: str | None = None


class DiaryEntryUpdate(BaseModel):
    wellbeing_rating: int | None = Field(None, ge=1, le=10)
    symptoms: list[str] | None = None
    comment: str | None = None


class DiaryEntryRead(BaseModel):
    id: UUID
    user_id: UUID
    entry_date: date
    wellbeing_rating: int
    symptoms: list[str]
    comment: str | None
    weather_pressure: float | None
    weather_kp_index: float | None
    risk_level: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
