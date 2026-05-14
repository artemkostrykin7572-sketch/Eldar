from datetime import date
from uuid import UUID

from advanced_alchemy.base import UUIDAuditBase
from sqlalchemy import Date, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON


class DiaryEntry(UUIDAuditBase):
    """Запись в дневнике."""

    __tablename__ = "diary_entries"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        index=True,
    )
    entry_date: Mapped[date] = mapped_column(Date, index=True)
    wellbeing_rating: Mapped[int] = mapped_column(Integer)

    symptoms: Mapped[list] = mapped_column(JSON, default=list)

    comment: Mapped[str | None] = mapped_column(String(2000), nullable=True)

    weather_pressure: Mapped[float | None] = mapped_column(Float, nullable=True)   # mmHg
    weather_kp_index: Mapped[float | None] = mapped_column(Float, nullable=True)

    risk_level: Mapped[str | None] = mapped_column(String(20), nullable=True)  # low/medium/high

    user: Mapped["UserProfile"] = relationship(
        "UserProfile",
        back_populates="diary_entries",
    )
