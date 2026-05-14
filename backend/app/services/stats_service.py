from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.diary_repository import DiaryRepository
from app.repositories.user_repository import UserRepository
from app.repositories.weather_repository import WeatherRepository
from app.schemas.stats import InsightItem, PersonalPrediction, UserStats

_BAD_WELLBEING = 4
_MIN_ENTRIES = 3


class StatsService:
    def __init__(self, session: AsyncSession) -> None:
        self._diary_repo = DiaryRepository(session=session)
        self._user_repo  = UserRepository(session=session)
        self._weather_repo = WeatherRepository(session=session)

    async def get_user_stats(self, user_id: UUID) -> UserStats:
        entries = await self._diary_repo.get_user_entries(user_id, limit=200, offset=0)
        user    = await self._user_repo.get(user_id)
        total   = len(entries)

        not_enough = UserStats(
            total_entries=total,
            has_enough_data=False,
            insights=[],
            personal_prediction=PersonalPrediction(
                adjustment=0,
                confidence=0.2,
                triggers=[],
                explanation=(
                    f"Нужно минимум {_MIN_ENTRIES} записи в дневнике. "
                    f"Сейчас: {total}."
                ),
            ),
        )
        if total < _MIN_ENTRIES:
            return not_enough

        # ── Insights ──────────────────────────────────────────────────────────
        def build_insight(subset: list, trigger: str) -> InsightItem | None:
            n = len(subset)
            if n < 2:
                return None
            bad = sum(1 for e in subset if e.wellbeing_rating <= _BAD_WELLBEING)
            pct = round(bad / n * 100)
            if pct < 30:
                return None
            return InsightItem(trigger=trigger, bad_days=bad, total_days=n, percent=pct)

        high_risk  = [e for e in entries if e.risk_level == "high"]
        kp_entries = [e for e in entries if e.weather_kp_index and e.weather_kp_index >= 4]

        insights: list[InsightItem] = list(filter(None, [
            build_insight(high_risk,  "высоком метеорологическом риске"),
            build_insight(kp_entries, "магнитных бурях"),
        ]))

        # ── Personal prediction (feature-matching over diary + weather) ───────
        feature_impact: dict[str, float] = {}
        feature_hits:   dict[str, int]   = {}

        for entry in entries:
            discomfort = max(0, 6 - entry.wellbeing_rating)
            if discomfort == 0:
                continue

            feats: set[str] = set()
            weather = await self._weather_repo.get_by_city_and_date(user.city, entry.entry_date)
            if weather is not None:
                if abs(weather.pressure_delta) >= 6: feats.add("pressure_drop")
                if weather.kp_index >= 4:            feats.add("kp_high")
                if abs(weather.temp_delta) >= 7:     feats.add("temp_delta")
            else:
                # fall back to diary-stored data
                if entry.weather_kp_index and entry.weather_kp_index >= 4:
                    feats.add("kp_high")
                if entry.risk_level == "high":
                    feats.add("high_risk")

            for feat in feats:
                feature_impact[feat] = feature_impact.get(feat, 0) + discomfort
                feature_hits[feat]   = feature_hits.get(feat, 0) + 1

        _label = {
            "pressure_drop": "скачки давления",
            "kp_high":       "магнитная активность",
            "temp_delta":    "перепад температуры",
            "high_risk":     "неблагоприятные условия",
        }
        triggers: list[str] = []
        adjustment = 0.0
        for feat, hits in feature_hits.items():
            impact = feature_impact.get(feat, 0) / hits
            if impact >= 1:
                triggers.append(_label.get(feat, feat))
                adjustment += impact / 1.8

        rounded_adj = int(max(0, min(3, round(adjustment))))
        confidence  = round(min(0.9, 0.25 + total * 0.05 + len(triggers) * 0.12), 2)

        if triggers:
            explanation = (
                "По записям дневника найдены повторяющиеся условия, "
                "при которых самочувствие ухудшалось."
            )
        else:
            explanation = (
                "Явной связи между погодными факторами и плохим "
                "самочувствием в дневнике не обнаружено."
            )

        return UserStats(
            total_entries=total,
            has_enough_data=True,
            insights=insights,
            personal_prediction=PersonalPrediction(
                adjustment=rounded_adj,
                confidence=confidence,
                triggers=triggers,
                explanation=explanation,
            ),
        )
