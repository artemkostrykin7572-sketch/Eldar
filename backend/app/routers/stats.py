from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db_session
from app.schemas.stats import UserStats
from app.services.stats_service import StatsService

router = APIRouter(prefix="/users/{user_id}/stats", tags=["stats"])


@router.get("/", response_model=UserStats)
async def get_stats(
    user_id: UUID,
    session: AsyncSession = Depends(get_db_session),
) -> UserStats:
    return await StatsService(session).get_user_stats(user_id)
