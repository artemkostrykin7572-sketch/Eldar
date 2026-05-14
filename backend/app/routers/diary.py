from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db_session
from app.schemas.diary import DiaryEntryCreate, DiaryEntryRead, DiaryEntryUpdate
from app.services.diary_service import DiaryService

router = APIRouter(prefix="/users/{user_id}/diary", tags=["diary"])


def _svc(session: AsyncSession = Depends(get_db_session)) -> DiaryService:
    return DiaryService(session)


@router.post("/", response_model=DiaryEntryRead, status_code=201)
async def create_entry(
    user_id: UUID,
    data: DiaryEntryCreate,
    svc: DiaryService = Depends(_svc),
):
    return await svc.create(user_id, data)


@router.get("/", response_model=list[DiaryEntryRead])
async def list_entries(
    user_id: UUID,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    svc: DiaryService = Depends(_svc),
):
    return await svc.list_for_user(user_id, limit=limit, offset=offset)


@router.get("/{entry_id}", response_model=DiaryEntryRead)
async def get_entry(user_id: UUID, entry_id: UUID, svc: DiaryService = Depends(_svc)):
    return await svc.get(entry_id)


@router.patch("/{entry_id}", response_model=DiaryEntryRead)
async def update_entry(
    user_id: UUID,
    entry_id: UUID,
    data: DiaryEntryUpdate,
    svc: DiaryService = Depends(_svc),
):
    return await svc.update(entry_id, data)


@router.delete("/{entry_id}", status_code=204)
async def delete_entry(user_id: UUID, entry_id: UUID, svc: DiaryService = Depends(_svc)):
    await svc.delete(entry_id)
