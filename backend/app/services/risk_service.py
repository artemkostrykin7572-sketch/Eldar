from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.risk import RiskScore
from app.repositories.risk_repository import RiskRepository
from app.repositories.user_repository import UserRepository
from app.repositories.weather_repository import WeatherRepository
from app.risk_engine import RiskEngine


class RiskService:
    def __init__(self, session: AsyncSession) -> None:
        self._risk_repo = RiskRepository(session=session)
        self._user_repo = UserRepository(session=session)
        self._weather_repo = WeatherRepository(session=session)

    async def calculate_for_city(self, user_id: UUID, city: str) -> list[RiskScore]:
        """Calculate and persist risk scores for all cached weather records of a city."""
        user = await self._user_repo.get(user_id)
        records = await self._weather_repo.get_forecast(city)

        scores: list[RiskScore] = []
        for record in records:
            result = RiskEngine.evaluate(
                temperature=record.temperature,
                pressure=record.pressure,
                humidity=record.humidity,
                wind_speed=record.wind_speed,
                kp_index=record.kp_index,
                temp_delta=record.temp_delta,
                pressure_delta=record.pressure_delta,
                sensitivity_hypertension=user.sensitivity_hypertension,
                sensitivity_hypotension=user.sensitivity_hypotension,
                sensitivity_joint_pain=user.sensitivity_joint_pain,
                sensitivity_headaches=user.sensitivity_headaches,
            )

            risk_score = await self._risk_repo.add(
                RiskScore(
                    user_id=user_id,
                    weather_record_id=record.id,
                    score=result.score,
                    level=result.level.value,
                    summary=result.summary,
                    reasons=result.reasons,
                    risk_factors=[
                        {
                            "name": f.name,
                            "level": f.level.value,
                            "value": f.value,
                            "explanation": f.explanation,
                        }
                        for f in result.factors
                    ],
                    calculated_at=datetime.now(UTC),
                )
            )
            scores.append(risk_score)

        return scores

    async def get_history(self, user_id: UUID, limit: int = 30) -> list[RiskScore]:
        return await self._risk_repo.get_user_history(user_id, limit=limit)
