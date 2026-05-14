from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import UserProfile
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserProfileCreate, UserProfileUpdate


class UserService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = UserRepository(session=session)

    async def create(self, data: UserProfileCreate) -> UserProfile:
        return await self._repo.add(UserProfile(**data.model_dump()))

    async def get(self, user_id: UUID) -> UserProfile:
        return await self._repo.get(user_id)

    async def update(self, user_id: UUID, data: UserProfileUpdate) -> UserProfile:
        user = await self._repo.get(user_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        return await self._repo.update(user)

    async def delete(self, user_id: UUID) -> None:
        await self._repo.delete(user_id)

    async def list_all(self) -> list[UserProfile]:
        result, _ = await self._repo.list_and_count()
        return result
