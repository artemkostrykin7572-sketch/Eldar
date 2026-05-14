from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class UserProfileCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    age: int | None = Field(None, ge=0, le=120)
    city: str = Field(..., min_length=1, max_length=100)
    sensitivity_hypertension: bool = False
    sensitivity_hypotension: bool = False
    sensitivity_joint_pain: bool = False
    sensitivity_headaches: bool = False
    notifications_enabled: bool = True


class UserProfileUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    age: int | None = Field(None, ge=0, le=120)
    city: str | None = Field(None, min_length=1, max_length=100)
    sensitivity_hypertension: bool | None = None
    sensitivity_hypotension: bool | None = None
    sensitivity_joint_pain: bool | None = None
    sensitivity_headaches: bool | None = None
    notifications_enabled: bool | None = None


class UserProfileRead(BaseModel):
    id: UUID
    name: str
    age: int | None
    city: str
    sensitivity_hypertension: bool
    sensitivity_hypotension: bool
    sensitivity_joint_pain: bool
    sensitivity_headaches: bool
    notifications_enabled: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
