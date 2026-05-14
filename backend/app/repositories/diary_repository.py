from datetime import date
from uuid import UUID

from advanced_alchemy.repository import SQLAlchemyAsyncRepository
from sqlalchemy import select

from app.models.diary import DiaryEntry


class DiaryRepository(SQLAlchemyAsyncRepository[DiaryEntry]):
    model_type = DiaryEntry

    async def get_user_entries(
        self,
        user_id: UUID,
        *,
        limit: int = 50,
        offset: int = 0,
    ) -> list[DiaryEntry]:
        stmt = (
            select(DiaryEntry)
            .where(DiaryEntry.user_id == user_id)
            .order_by(DiaryEntry.entry_date.desc())
            .limit(limit)
            .offset(offset)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_date(self, user_id: UUID, entry_date: date) -> DiaryEntry | None:
        stmt = select(DiaryEntry).where(
            DiaryEntry.user_id == user_id,
            DiaryEntry.entry_date == entry_date,
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()
