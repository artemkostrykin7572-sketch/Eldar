from datetime import datetime
from uuid import UUID

from advanced_alchemy.base import UUIDAuditBase
from sqlalchemy import DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON


class RiskScore(UUIDAuditBase):
    """Вычесленный риск для конкретного пользователя и дня."""

    __tablename__ = "risk_scores"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
    )
    weather_record_id: Mapped[UUID] = mapped_column(
        ForeignKey("weather_records.id", ondelete="CASCADE"),
        index=True,
    )

    score: Mapped[float] = mapped_column(Float)
    level: Mapped[str] = mapped_column(String(20))
    summary: Mapped[str] = mapped_column(String(500))

    reasons: Mapped[list] = mapped_column(JSON, default=list)
    risk_factors: Mapped[list] = mapped_column(JSON, default=list)

    calculated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    user: Mapped["UserProfile"] = relationship(
        "UserProfile",
        back_populates="risk_scores",
    )
    weather_record: Mapped["WeatherRecord"] = relationship("WeatherRecord")  # noqa: F821
