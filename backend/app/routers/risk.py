from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db_session
from app.schemas.risk import RiskScoreRead
from app.services.risk_service import RiskService

router = APIRouter(prefix="/users/{user_id}/risk", tags=["risk"])


def _svc(session: AsyncSession = Depends(get_db_session)) -> RiskService:
    return RiskService(session)


@router.post("/calculate", response_model=list[RiskScoreRead], status_code=201)
async def calculate_risk(
    user_id: UUID,
    city: str = Query(..., min_length=1),
    svc: RiskService = Depends(_svc),
):
    """Calculate risk scores for all cached weather records for the city."""
    return await svc.calculate_for_city(user_id, city)


@router.get("/history", response_model=list[RiskScoreRead])
async def risk_history(
    user_id: UUID,
    limit: int = Query(30, ge=1, le=100),
    svc: RiskService = Depends(_svc),
):
    return await svc.get_history(user_id, limit=limit)
