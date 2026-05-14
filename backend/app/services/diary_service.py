from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.diary import DiaryEntry
from app.repositories.diary_repository import DiaryRepository
from app.schemas.diary import DiaryEntryCreate, DiaryEntryUpdate


class DiaryService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = DiaryRepository(session=session)

    async def create(self, user_id: UUID, data: DiaryEntryCreate) -> DiaryEntry:
        return await self._repo.add(
            DiaryEntry(
                user_id=user_id,
                **data.model_dump(),
            )
        )

    async def get(self, entry_id: UUID) -> DiaryEntry:
        return await self._repo.get(entry_id)

    async def update(self, entry_id: UUID, data: DiaryEntryUpdate) -> DiaryEntry:
        entry = await self._repo.get(entry_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(entry, field, value)
        return await self._repo.update(entry)

    async def delete(self, entry_id: UUID) -> None:
        await self._repo.delete(entry_id)

    async def list_for_user(
        self,
        user_id: UUID,
        *,
        limit: int = 50,
        offset: int = 0,
    ) -> list[DiaryEntry]:
        return await self._repo.get_user_entries(user_id, limit=limit, offset=offset)
