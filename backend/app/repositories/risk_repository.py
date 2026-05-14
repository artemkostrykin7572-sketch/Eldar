from datetime import date
from uuid import UUID

from advanced_alchemy.repository import SQLAlchemyAsyncRepository
from sqlalchemy import select

from app.models.risk import RiskScore


class RiskRepository(SQLAlchemyAsyncRepository[RiskScore]):
    model_type = RiskScore

    async def get_user_history(
        self,
        user_id: UUID,
        *,
        limit: int = 30,
    ) -> list[RiskScore]:
        stmt = (
            select(RiskScore)
            .where(RiskScore.user_id == user_id)
            .order_by(RiskScore.calculated_at.desc())
            .limit(limit)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_for_date(self, user_id: UUID, target_date: date) -> RiskScore | None:
        """Return the most recent risk score calculated for a specific date."""
        stmt = (
            select(RiskScore)
            .join(RiskScore.weather_record)
            .where(
                RiskScore.user_id == user_id,
            )
            .order_by(RiskScore.calculated_at.desc())
            .limit(1)
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()
