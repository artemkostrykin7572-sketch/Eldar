from advanced_alchemy.base import UUIDAuditBase
from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship


class UserProfile(UUIDAuditBase):
    __tablename__ = "user_profiles"

    name: Mapped[str] = mapped_column(String(100))
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    city: Mapped[str] = mapped_column(String(100))

    sensitivity_hypertension: Mapped[bool] = mapped_column(Boolean, default=False)
    sensitivity_hypotension: Mapped[bool] = mapped_column(Boolean, default=False)
    sensitivity_joint_pain: Mapped[bool] = mapped_column(Boolean, default=False)
    sensitivity_headaches: Mapped[bool] = mapped_column(Boolean, default=False)

    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    diary_entries: Mapped[list["DiaryEntry"]] = relationship(
        "DiaryEntry",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    risk_scores: Mapped[list["RiskScore"]] = relationship(
        "RiskScore",
        back_populates="user",
        cascade="all, delete-orphan",
    )
