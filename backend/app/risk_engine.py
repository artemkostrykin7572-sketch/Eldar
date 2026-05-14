"""
Deterministic risk engine — port of the Flutter RiskEngine.

Thresholds are identical to the Dart implementation so Flutter and backend
produce the same scores when given the same inputs.
"""

from dataclasses import dataclass, field
from enum import Enum


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


@dataclass
class RiskFactor:
    name: str
    level: RiskLevel
    value: float
    explanation: str


@dataclass
class RiskResult:
    score: float          # 0–10
    level: RiskLevel
    summary: str
    reasons: list[str]
    factors: list[RiskFactor] = field(default_factory=list)


class RiskEngine:
    # mmHg pressure delta thresholds
    PRESSURE_YELLOW_SENSITIVE = 6
    PRESSURE_RED_SENSITIVE = 10
    PRESSURE_YELLOW_NORMAL = 8
    PRESSURE_RED_NORMAL = 12

    # °C temperature delta thresholds
    TEMP_YELLOW = 7
    TEMP_RED = 10

    # Planetary K-index thresholds
    KP_YELLOW = 4
    KP_RED = 5

    # Humidity % thresholds for joint-sensitive users
    HUMIDITY_LOW = 30
    HUMIDITY_HIGH = 80

    @classmethod
    def evaluate(
        cls,
        *,
        temperature: float,
        pressure: float,
        humidity: float,
        wind_speed: float,
        kp_index: float,
        temp_delta: float,
        pressure_delta: float,
        sensitivity_hypertension: bool = False,
        sensitivity_hypotension: bool = False,
        sensitivity_joint_pain: bool = False,
        sensitivity_headaches: bool = False,
    ) -> RiskResult:
        factors: list[RiskFactor] = []

        # --- Pressure ---
        is_bp_sensitive = sensitivity_hypertension or sensitivity_hypotension
        p_yellow = cls.PRESSURE_YELLOW_SENSITIVE if is_bp_sensitive else cls.PRESSURE_YELLOW_NORMAL
        p_red = cls.PRESSURE_RED_SENSITIVE if is_bp_sensitive else cls.PRESSURE_RED_NORMAL
        abs_pressure = abs(pressure_delta)

        if abs_pressure >= p_red:
            p_level = RiskLevel.HIGH
            p_text = f"Резкий перепад давления: {abs_pressure:.1f} мм рт.ст."
        elif abs_pressure >= p_yellow:
            p_level = RiskLevel.MEDIUM
            p_text = f"Заметное изменение давления: {abs_pressure:.1f} мм рт.ст."
        else:
            p_level = RiskLevel.LOW
            p_text = f"Давление стабильно, изменение {abs_pressure:.1f} мм рт.ст."

        factors.append(RiskFactor(name="pressure", level=p_level, value=abs_pressure, explanation=p_text))

        # --- Temperature ---
        abs_temp = abs(temp_delta)

        if abs_temp >= cls.TEMP_RED:
            t_level = RiskLevel.HIGH
            t_text = f"Резкий перепад температуры: {abs_temp:.1f}°C за сутки"
        elif abs_temp >= cls.TEMP_YELLOW:
            t_level = RiskLevel.MEDIUM
            t_text = f"Заметный перепад температуры: {abs_temp:.1f}°C за сутки"
        else:
            t_level = RiskLevel.LOW
            t_text = f"Температура стабильна, изменение {abs_temp:.1f}°C"

        factors.append(RiskFactor(name="temperature", level=t_level, value=abs_temp, explanation=t_text))

        # --- Geomagnetic activity ---
        if kp_index >= cls.KP_RED:
            kp_level = RiskLevel.HIGH
            kp_text = f"Магнитная буря: Kp = {kp_index:.1f}"
        elif kp_index >= cls.KP_YELLOW:
            kp_level = RiskLevel.MEDIUM
            kp_text = f"Повышенная геомагнитная активность: Kp = {kp_index:.1f}"
        else:
            kp_level = RiskLevel.LOW
            kp_text = f"Геомагнитная активность нормальная: Kp = {kp_index:.1f}"

        factors.append(RiskFactor(name="geomagnetic", level=kp_level, value=kp_index, explanation=kp_text))

        # --- Humidity (relevant only for joint-sensitive users) ---
        if sensitivity_joint_pain:
            if humidity < cls.HUMIDITY_LOW:
                h_level = RiskLevel.MEDIUM
                h_text = f"Низкая влажность {humidity:.0f}% — возможен дискомфорт в суставах"
            elif humidity > cls.HUMIDITY_HIGH:
                h_level = RiskLevel.MEDIUM
                h_text = f"Высокая влажность {humidity:.0f}% — возможен дискомфорт в суставах"
            else:
                h_level = RiskLevel.LOW
                h_text = f"Влажность в норме: {humidity:.0f}%"
        else:
            h_level = RiskLevel.LOW
            h_text = f"Влажность: {humidity:.0f}%"

        factors.append(RiskFactor(name="humidity", level=h_level, value=humidity, explanation=h_text))

        # --- Aggregate ---
        high_count = sum(1 for f in factors if f.level == RiskLevel.HIGH)
        medium_count = sum(1 for f in factors if f.level == RiskLevel.MEDIUM)

        if high_count >= 1 or medium_count >= 2:
            overall = RiskLevel.HIGH
            score = min(7.0 + high_count * 1.5 + medium_count * 0.25, 10.0)
            summary = "Высокий риск ухудшения самочувствия. Рекомендуется соблюдать режим и принять меры."
        elif medium_count == 1:
            overall = RiskLevel.MEDIUM
            score = 4.0 + medium_count * 0.5
            summary = "Умеренный риск. Следите за самочувствием и не перегружайте себя."
        else:
            overall = RiskLevel.LOW
            score = max(1.0, min(abs_pressure * 0.2 + abs_temp * 0.1, 3.0))
            summary = "Погодные условия благоприятны для большинства людей."

        reasons = [f.explanation for f in factors if f.level != RiskLevel.LOW]

        return RiskResult(
            score=round(score, 1),
            level=overall,
            summary=summary,
            reasons=reasons,
            factors=factors,
        )
