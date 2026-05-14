from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class RiskFactorRead(BaseModel):
    name: str
    level: str
    value: float
    explanation: str


class RiskScoreRead(BaseModel):
    id: UUID
    user_id: UUID
    weather_record_id: UUID
    score: float
    level: str
    summary: str
    reasons: list[str]
    risk_factors: list[RiskFactorRead]
    calculated_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class RiskCalculateRequest(BaseModel):
    user_id: UUID
    city: str
