import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.database import engine
from app.models import DiaryEntry, RiskScore, UserProfile, WeatherRecord  # noqa: F401 — registers models with metadata
from app.routers import diary_router, risk_router, stats_router, users_router, weather_router

_ = (UserProfile, WeatherRecord, DiaryEntry, RiskScore)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await engine.dispose()


app = FastAPI(
    title="Climo API",
    description="Backend for the Climo weather-sensitivity mobile app",
    version="0.1.0",
    lifespan=lifespan,
)


@app.exception_handler(Exception)
async def debug_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": type(exc).__name__, "detail": str(exc), "trace": traceback.format_exc()},
    )

app.include_router(users_router)
app.include_router(weather_router)
app.include_router(diary_router)
app.include_router(risk_router)
app.include_router(stats_router)


@app.get("/health", tags=["system"])
async def health():
    return {"status": "ok"}
