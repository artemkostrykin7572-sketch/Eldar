from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db_session
from app.schemas.user import UserProfileCreate, UserProfileRead, UserProfileUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


def _svc(session: AsyncSession = Depends(get_db_session)) -> UserService:
    return UserService(session)


@router.post("/", response_model=UserProfileRead, status_code=201)
async def create_user(data: UserProfileCreate, svc: UserService = Depends(_svc)):
    return await svc.create(data)


@router.get("/{user_id}", response_model=UserProfileRead)
async def get_user(user_id: UUID, svc: UserService = Depends(_svc)):
    return await svc.get(user_id)


@router.patch("/{user_id}", response_model=UserProfileRead)
async def update_user(user_id: UUID, data: UserProfileUpdate, svc: UserService = Depends(_svc)):
    return await svc.update(user_id, data)


@router.delete("/{user_id}", status_code=204)
async def delete_user(user_id: UUID, svc: UserService = Depends(_svc)):
    await svc.delete(user_id)
