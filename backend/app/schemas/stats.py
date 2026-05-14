from pydantic import BaseModel


class InsightItem(BaseModel):
    trigger: str
    bad_days: int
    total_days: int
    percent: int


class PersonalPrediction(BaseModel):
    adjustment: int
    confidence: float
    triggers: list[str]
    explanation: str


class UserStats(BaseModel):
    total_entries: int
    has_enough_data: bool
    insights: list[InsightItem]
    personal_prediction: PersonalPrediction
