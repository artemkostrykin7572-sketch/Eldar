from app.routers.diary import router as diary_router
from app.routers.risk import router as risk_router
from app.routers.stats import router as stats_router
from app.routers.users import router as users_router
from app.routers.weather import router as weather_router

__all__ = ["diary_router", "risk_router", "stats_router", "users_router", "weather_router"]
