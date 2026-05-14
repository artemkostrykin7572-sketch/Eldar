from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db_session
from app.repositories.weather_repository import WeatherRepository
from app.schemas.weather import WeatherRecordRead
from app.services.weather_service import WeatherService

router = APIRouter(prefix="/weather", tags=["weather"])


def _svc(session: AsyncSession = Depends(get_db_session)) -> WeatherService:
    return WeatherService(WeatherRepository(session=session))


@router.get("/forecast", response_model=list[WeatherRecordRead])
async def get_forecast(
    city: str = Query(..., min_length=1),
    days: int = Query(5, ge=1, le=10),
    svc: WeatherService = Depends(_svc),
):
    """Return (and refresh if stale) weather forecast for a city."""
    return await svc.get_forecast(city, days)


@router.post("/fetch", response_model=list[WeatherRecordRead], status_code=201)
async def force_fetch(
    city: str = Query(..., min_length=1),
    days: int = Query(5, ge=1, le=10),
    svc: WeatherService = Depends(_svc),
):
    """Force-refresh weather data from external APIs."""
    return await svc.fetch_and_store(city, days)
