import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ClimoApp());
}

// ─── App Root ─────────────────────────────────────────────────────────────────

class ClimoApp extends StatelessWidget {
  const ClimoApp({this.enableNetwork = true, super.key});
  final bool enableNetwork;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'МетеоДневник',
      debugShowCheckedModeBanner: false,
      theme: ClimoTheme.light(),
      home: ClimoShell(enableNetwork: enableNetwork),
    );
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class ClimoTheme {
  static const background   = Color(0xFFF7F5FF);
  static const text         = Color(0xFF1C1340);
  static const mutedText    = Color(0xFF7B7898);
  static const blue         = Color(0xFF7C3AED); // primary purple
  static const purpleLight  = Color(0xFFEDE9FE);
  static const purpleSoft   = Color(0xFFF5F3FF);
  static const mint         = Color(0xFF10B981);
  static const mintLight    = Color(0xFFD1FAE5);
  static const gradientTop  = Color(0xFFFFFFFF);
  static const gradientBot  = Color(0xFFF0EDFF);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
      textTheme: const TextTheme(
        displaySmall:  TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: text,      height: 1.05),
        headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text,      height: 1.12),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text,      height: 1.18),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text,      height: 1.22),
        bodyLarge:     TextStyle(fontSize: 16, color: mutedText, height: 1.42),
        bodyMedium:    TextStyle(fontSize: 13, color: mutedText, height: 1.34),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: purpleSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: purpleLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(color: sel ? blue : const Color(0xFFB0AEC8), size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            color: sel ? blue : const Color(0xFFB0AEC8),
            fontSize: 12,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 8,
        thumbColor: Colors.white,
        overlayColor: Color(0x127C3AED),
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Color(0xFFB0AEC8), width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? blue : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum RiskLevel {
  low('низкий риск', 'Норма'),
  medium('умеренный риск', 'Внимание'),
  high('высокий риск', 'Опасно');

  const RiskLevel(this.label, this.badge);
  final String label;
  final String badge;
}

enum RecommendationCategory {
  activity('Физическая активность',    Icons.monitor_heart_outlined),
  nutrition('Питание и гидратация',    Icons.emoji_food_beverage_outlined),
  routine('Бытовые советы и режим',    Icons.home_outlined),
  control('Контроль самочувствия',     Icons.favorite_border);

  const RecommendationCategory(this.title, this.icon);
  final String title;
  final IconData icon;
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.city,
    required this.hasHypertension,
    required this.hasHypotension,
    required this.hasJointSensitivity,
    required this.hasHeadaches,
    required this.notificationsEnabled,
    required this.notifyPressure,
    required this.notifyKp,
    required this.notifyHumidity,
    required this.notifyTemperature,
    required this.disclaimerAccepted,
  });

  final String name;
  final int age;
  final String city;
  final bool hasHypertension;
  final bool hasHypotension;
  final bool hasJointSensitivity;
  final bool hasHeadaches;
  final bool notificationsEnabled;
  final bool notifyPressure;
  final bool notifyKp;
  final bool notifyHumidity;
  final bool notifyTemperature;
  final bool disclaimerAccepted;

  UserProfile copyWith({
    String? name,
    int? age,
    String? city,
    bool? hasHypertension,
    bool? hasHypotension,
    bool? hasJointSensitivity,
    bool? hasHeadaches,
    bool? notificationsEnabled,
    bool? notifyPressure,
    bool? notifyKp,
    bool? notifyHumidity,
    bool? notifyTemperature,
    bool? disclaimerAccepted,
  }) => UserProfile(
    name: name ?? this.name,
    age: age ?? this.age,
    city: city ?? this.city,
    hasHypertension: hasHypertension ?? this.hasHypertension,
    hasHypotension: hasHypotension ?? this.hasHypotension,
    hasJointSensitivity: hasJointSensitivity ?? this.hasJointSensitivity,
    hasHeadaches: hasHeadaches ?? this.hasHeadaches,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    notifyPressure: notifyPressure ?? this.notifyPressure,
    notifyKp: notifyKp ?? this.notifyKp,
    notifyHumidity: notifyHumidity ?? this.notifyHumidity,
    notifyTemperature: notifyTemperature ?? this.notifyTemperature,
    disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
  );
}

class WeatherRecord {
  const WeatherRecord({
    required this.time,
    required this.temperature,
    required this.temperatureDelta,
    required this.pressure,
    required this.pressureDelta,
    required this.humidity,
    required this.windSpeed,
    required this.kpIndex,
    required this.source,
  });

  final DateTime time;
  final double temperature;
  final double temperatureDelta;
  final double pressure;
  final double pressureDelta;
  final int humidity;
  final double windSpeed;
  final double kpIndex;
  final String source;
}

class GeoLocation {
  const GeoLocation({required this.name, required this.latitude, required this.longitude});
  final String name;
  final double latitude;
  final double longitude;
}

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RiskFactor {
  const RiskFactor({
    required this.tag,
    required this.title,
    required this.value,
    required this.level,
    required this.icon,
    required this.explanation,
  });
  final String tag;
  final String title;
  final String value;
  final RiskLevel level;
  final IconData icon;
  final String explanation;
}

class RiskResult {
  const RiskResult({
    required this.score,
    required this.level,
    required this.reasons,
    required this.factors,
    required this.summary,
  });
  final int score;
  final RiskLevel level;
  final List<String> reasons;
  final List<RiskFactor> factors;
  final String summary;
}

class DiaryEntry {
  const DiaryEntry({
    required this.time,
    required this.wellbeing,
    required this.symptoms,
    required this.comment,
    required this.weather,
    required this.risk,
  });
  final DateTime time;
  final int wellbeing;
  final List<String> symptoms;
  final String comment;
  final WeatherRecord weather;
  final RiskResult risk;
}

class RecommendationItem {
  const RecommendationItem({
    required this.id,
    required this.category,
    required this.text,
    required this.tags,
    required this.profiles,
    required this.priority,
  });
  final int id;
  final RecommendationCategory category;
  final String text;
  final Set<String> tags;
  final Set<String> profiles;
  final int priority;
}

class MlRiskPrediction {
  const MlRiskPrediction({
    required this.predictedScore,
    required this.adjustment,
    required this.confidence,
    required this.triggers,
    required this.explanation,
  });
  final int predictedScore;
  final int adjustment;
  final double confidence;
  final List<String> triggers;
  final String explanation;
}

// ─── Services ─────────────────────────────────────────────────────────────────

class WeatherApiService {
  const WeatherApiService({http.Client? client}) : _client = client;
  final http.Client? _client;

  Future<List<WeatherRecord>> fetchForecast(String city) async {
    final client = _client ?? http.Client();
    try {
      final location = await _fetchLocation(client, city);
      final kpIndex = await _fetchKpIndex(client);
      return _fetchOpenMeteoForecast(client, location, kpIndex);
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<GeoLocation> _fetchLocation(http.Client client, String city) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city, 'count': '1', 'language': 'ru', 'format': 'json',
    });
    final response = await client.get(uri);
    _ensureOk(response, 'геокодинг Open-Meteo');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) throw WeatherApiException('Город "$city" не найден.');
    final first = results.first as Map<String, dynamic>;
    return GeoLocation(
      name: (first['name'] as String?) ?? city,
      latitude: (first['latitude'] as num).toDouble(),
      longitude: (first['longitude'] as num).toDouble(),
    );
  }

  Future<double> _fetchKpIndex(http.Client client) async {
    final uri = Uri.https('services.swpc.noaa.gov', '/json/planetary_k_index_1m.json');
    final response = await client.get(uri);
    _ensureOk(response, 'NOAA SWPC Kp');
    final rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) return 0;
    final latest = rows.last as Map<String, dynamic>;
    final estimated = latest['estimated_kp'];
    final index = latest['kp_index'];
    if (estimated is num) return estimated.toDouble();
    if (index is num) return index.toDouble();
    return 0;
  }

  Future<List<WeatherRecord>> _fetchOpenMeteoForecast(
    http.Client client, GeoLocation location, double kpIndex,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toStringAsFixed(4),
      'longitude': location.longitude.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,pressure_msl,wind_speed_10m',
      'daily': 'temperature_2m_mean,relative_humidity_2m_mean,pressure_msl_mean,wind_speed_10m_max',
      'forecast_days': '5', 'past_days': '1', 'timezone': 'auto', 'wind_speed_unit': 'ms',
    });
    final response = await client.get(uri);
    _ensureOk(response, 'прогноз Open-Meteo');
    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>;
    final daily   = data['daily']   as Map<String, dynamic>;
    final times       = (daily['time'] as List).cast<String>();
    final tempMean    = _numList(daily['temperature_2m_mean']);
    final humidityMean= _numList(daily['relative_humidity_2m_mean']);
    final pressureMean= _numList(daily['pressure_msl_mean']);
    final windMax     = _numList(daily['wind_speed_10m_max']);
    final startIndex  = times.length > 5 ? 1 : 0;
    final records = <WeatherRecord>[];
    for (var i = startIndex; i < times.length && records.length < 5; i++) {
      final prevI    = math.max(0, i - 1);
      final isToday  = records.isEmpty;
      final pressure = isToday
          ? _hPaToMmHg((current['pressure_msl'] as num).toDouble())
          : _hPaToMmHg(pressureMean[i]);
      final prevPressure  = _hPaToMmHg(pressureMean[prevI]);
      final temperature   = isToday ? (current['temperature_2m'] as num).toDouble() : tempMean[i];
      final humidity      = isToday ? (current['relative_humidity_2m'] as num).round() : humidityMean[i].round();
      final wind          = isToday ? (current['wind_speed_10m'] as num).toDouble() : windMax[i];
      records.add(WeatherRecord(
        time:             DateTime.parse(isToday ? current['time'] as String : times[i]),
        temperature:      temperature,
        temperatureDelta: temperature - tempMean[prevI],
        pressure:         pressure,
        pressureDelta:    pressure - prevPressure,
        humidity:         humidity,
        windSpeed:        wind,
        kpIndex:          kpIndex,
        source:           'Open-Meteo + NOAA SWPC',
      ));
    }
    if (records.isEmpty) throw const WeatherApiException('Open-Meteo вернул пустой прогноз.');
    return records;
  }

  static List<double> _numList(Object? value) =>
      ((value as List?) ?? const []).map((e) => (e as num).toDouble()).toList();
  static double _hPaToMmHg(double hPa) => hPa * 0.750061683;
  static void _ensureOk(http.Response r, String src) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw WeatherApiException('Ошибка $src: HTTP ${r.statusCode}.');
    }
  }
}

// ─── Backend API Service ──────────────────────────────────────────────────────

// Android emulator → 10.0.2.2 maps to host localhost.
// Real device → change to your machine's local IP, e.g. http://192.168.1.X:8000
const _kBackendBase = 'http://10.0.2.2:8000';

class BackendApiService {
  const BackendApiService();

  // ── User ──────────────────────────────────────────────────────────────────

  Future<String> getOrCreateUser(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_id');
    if (saved != null) return saved;

    final response = await http.post(
      Uri.parse('$_kBackendBase/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': profile.name,
        'age': profile.age,
        'city': profile.city,
        'sensitivity_hypertension': profile.hasHypertension,
        'sensitivity_hypotension': profile.hasHypotension,
        'sensitivity_joint_pain': profile.hasJointSensitivity,
        'sensitivity_headaches': profile.hasHeadaches,
        'notifications_enabled': profile.notificationsEnabled,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Не удалось создать профиль: HTTP ${response.statusCode}');
    }
    final id = (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
    await prefs.setString('user_id', id);
    return id;
  }

  Future<void> updateProfile(String userId, UserProfile profile) async {
    await http.patch(
      Uri.parse('$_kBackendBase/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': profile.name,
        'age': profile.age,
        'city': profile.city,
        'sensitivity_hypertension': profile.hasHypertension,
        'sensitivity_hypotension': profile.hasHypotension,
        'sensitivity_joint_pain': profile.hasJointSensitivity,
        'sensitivity_headaches': profile.hasHeadaches,
        'notifications_enabled': profile.notificationsEnabled,
      }),
    );
  }

  // ── Weather ───────────────────────────────────────────────────────────────

  Future<List<WeatherRecord>> fetchForecast(String city) async {
    final uri = Uri.parse('$_kBackendBase/weather/forecast')
        .replace(queryParameters: {'city': city, 'days': '5'});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw WeatherApiException('Backend weather: HTTP ${response.statusCode}');
    }
    final list = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    list.sort((a, b) =>
        (a['forecast_date'] as String).compareTo(b['forecast_date'] as String));
    return list.map((e) => WeatherRecord(
      time:             DateTime.parse(e['forecast_date'] as String),
      temperature:      (e['temperature']   as num).toDouble(),
      temperatureDelta: (e['temp_delta']     as num).toDouble(),
      pressure:         (e['pressure']       as num).toDouble(),
      pressureDelta:    (e['pressure_delta'] as num).toDouble(),
      humidity:         (e['humidity']       as num).round(),
      windSpeed:        (e['wind_speed']     as num).toDouble(),
      kpIndex:          (e['kp_index']       as num).toDouble(),
      source:           'МетеоДневник API',
    )).toList();
  }

  // ── Diary ─────────────────────────────────────────────────────────────────

  Future<void> saveDiaryEntry(String userId, DiaryEntry entry) async {
    final response = await http.post(
      Uri.parse('$_kBackendBase/users/$userId/diary/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'entry_date':       entry.time.toIso8601String().substring(0, 10),
        'wellbeing_rating': entry.wellbeing,
        'symptoms':         entry.symptoms,
        'comment':          entry.comment,
        'weather_pressure': entry.weather.pressure,
        'weather_kp_index': entry.weather.kpIndex,
        'risk_level':       entry.risk.level.name,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Не удалось сохранить запись: HTTP ${response.statusCode}');
    }
  }

  Future<List<DiaryEntry>> loadDiaryEntries(
    String userId,
    WeatherRecord fallback,
    RiskEngine riskEngine,
    UserProfile profile,
  ) async {
    final uri = Uri.parse('$_kBackendBase/users/$userId/diary/')
        .replace(queryParameters: {'limit': '50', 'offset': '0'});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить дневник: HTTP ${response.statusCode}');
    }
    final list = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    return list.map((e) {
      final pressure = (e['weather_pressure'] as num?)?.toDouble() ?? fallback.pressure;
      final kpIndex  = (e['weather_kp_index']  as num?)?.toDouble() ?? fallback.kpIndex;
      final entryDate = DateTime.parse(e['entry_date'] as String);
      final w = WeatherRecord(
        time: entryDate, temperature: fallback.temperature,
        temperatureDelta: fallback.temperatureDelta, pressure: pressure,
        pressureDelta: fallback.pressureDelta, humidity: fallback.humidity,
        windSpeed: fallback.windSpeed, kpIndex: kpIndex, source: 'МетеоДневник API',
      );
      return DiaryEntry(
        time: entryDate,
        wellbeing: e['wellbeing_rating'] as int,
        symptoms: (e['symptoms'] as List).cast<String>(),
        comment: (e['comment'] as String?) ?? '',
        weather: w,
        risk: riskEngine.evaluate(w, profile),
      );
    }).toList();
  }
}

// ─── Engines ──────────────────────────────────────────────────────────────────

class RiskEngine {
  RiskResult evaluate(WeatherRecord weather, UserProfile profile) {
    final pressureYellow = profile.hasHypertension || profile.hasHypotension ? 6.0 : 8.0;
    final pressureRed    = profile.hasHypertension || profile.hasHypotension ? 10.0 : 12.0;
    const tempYellow = 7.0; const tempRed = 10.0;
    final humidityYellow = profile.hasJointSensitivity ? 70 : 75;
    final humidityRed    = profile.hasJointSensitivity ? 82 : 88;

    final factors = <RiskFactor>[
      RiskFactor(
        tag: 'pressure_drop', title: 'Давление',
        value: '${weather.pressure.round()} мм рт.ст., ${signed(weather.pressureDelta)} за сутки',
        level: factorLevel(weather.pressureDelta.abs(), pressureYellow, pressureRed),
        icon: Icons.waves,
        explanation: 'Перепад давления может усиливать головную боль.',
      ),
      RiskFactor(
        tag: 'kp_high', title: 'Геомагнитная активность',
        value: 'Kp-индекс ${weather.kpIndex.round()}',
        level: factorLevel(weather.kpIndex, 4, 5),
        icon: Icons.cloud_queue,
        explanation: 'Повышенный Kp указывает на геомагнитную активность.',
      ),
      RiskFactor(
        tag: 'temp_delta', title: 'Температура',
        value: '${weather.temperature.round() > 0 ? '+' : ''}${weather.temperature.round()}°C',
        level: factorLevel(weather.temperatureDelta.abs(), tempYellow, tempRed),
        icon: Icons.thermostat_outlined,
        explanation: 'Перепад более 7-10°C считается значимым триггером.',
      ),
      RiskFactor(
        tag: 'humidity_high', title: 'Влажность',
        value: '${weather.humidity}%',
        level: weather.humidity < 30
            ? RiskLevel.medium
            : factorLevel(weather.humidity.toDouble(), humidityYellow.toDouble(), humidityRed.toDouble()),
        icon: Icons.water_drop_outlined,
        explanation: 'Высокая или низкая влажность может усиливать усталость.',
      ),
    ];

    final active   = factors.where((f) => f.level != RiskLevel.low);
    final redCount = factors.where((f) => f.level == RiskLevel.high).length;
    var level = RiskLevel.low;
    if (redCount > 0 || active.length >= 2) {
      level = RiskLevel.high;
    } else if (active.isNotEmpty) {
      level = RiskLevel.medium;
    }

    final score = switch (level) {
      RiskLevel.low    => 3,
      RiskLevel.medium => 4,
      RiskLevel.high   => math.min(9, 6 + active.length),
    };
    return RiskResult(
      score: score, level: level,
      reasons: active.isEmpty ? ['условия стабильны'] : active.map((f) => f.title.toLowerCase()).toList(),
      factors: factors,
      summary: switch (level) {
        RiskLevel.low    => 'Факторы в пределах нормы. День выглядит спокойным.',
        RiskLevel.medium => 'Один фактор отклонен от нормы. Возможен легкий дискомфорт.',
        RiskLevel.high   => 'Сочетание триггеров повышает нагрузку на организм.',
      },
    );
  }

  static RiskLevel factorLevel(double v, double y, double r) {
    if (v >= r) return RiskLevel.high;
    if (v >= y) return RiskLevel.medium;
    return RiskLevel.low;
  }
  static String signed(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}';
}

class RecommendationEngine {
  List<RecommendationItem> select(
    List<RecommendationItem> all, RiskResult risk, UserProfile profile,
  ) {
    final tags = risk.factors.where((f) => f.level != RiskLevel.low).map((f) => f.tag).toSet();
    final profileTags = <String>{
      if (profile.hasHypertension)    'profile_hypertension',
      if (profile.hasHypotension)     'profile_hypotension',
      if (profile.hasJointSensitivity)'profile_joints',
      if (profile.hasHeadaches)       'profile_headache',
    };
    final relevant = all.where((item) {
      final hasWeather = item.tags.any(tags.contains);
      final hasProfile = item.profiles.isEmpty || item.profiles.any(profileTags.contains);
      return hasWeather && hasProfile;
    }).toList()..sort((a, b) => b.priority.compareTo(a.priority));
    if (relevant.isEmpty) return all.where((i) => i.tags.contains('normal')).take(3).toList();
    return relevant.take(6).toList();
  }
}

class PersonalRiskModel {
  const PersonalRiskModel();

  MlRiskPrediction predict({
    required List<DiaryEntry> diary,
    required WeatherRecord weather,
    required RiskResult baseRisk,
  }) {
    if (diary.length < 3) {
      return MlRiskPrediction(
        predictedScore: baseRisk.score, adjustment: 0, confidence: 0.2,
        triggers: const ['недостаточно записей'],
        explanation: 'Модель ожидает минимум 3 записи дневника. Сейчас используется базовый скоринг.',
      );
    }
    final currentFeatures = _features(weather);
    final featureImpact = <String, double>{};
    final featureHits   = <String, int>{};
    for (final entry in diary) {
      final discomfort = math.max(0, 6 - entry.wellbeing);
      if (discomfort == 0) continue;
      for (final feature in _features(entry.weather)) {
        featureImpact[feature] = (featureImpact[feature] ?? 0) + discomfort;
        featureHits[feature]   = (featureHits[feature] ?? 0) + 1;
      }
    }
    final triggers = <String>[];
    var adjustment = 0.0;
    for (final feature in currentFeatures) {
      final hits = featureHits[feature] ?? 0;
      if (hits == 0) continue;
      final impact = (featureImpact[feature] ?? 0) / hits;
      if (impact >= 1) { triggers.add(_featureLabel(feature)); adjustment += impact / 1.8; }
    }
    final roundedAdj     = adjustment.round().clamp(0, 3).toInt();
    final predictedScore = (baseRisk.score + roundedAdj).clamp(1, 10).toInt();
    final confidence     = math.min(0.9, 0.25 + diary.length * 0.05 + triggers.length * 0.12);
    return MlRiskPrediction(
      predictedScore: predictedScore, adjustment: roundedAdj, confidence: confidence,
      triggers: triggers.isEmpty ? const ['явных персональных триггеров нет'] : triggers,
      explanation: triggers.isEmpty
          ? 'Локальная ML-модель не нашла устойчивого совпадения между плохим самочувствием и текущими факторами.'
          : 'Локальная ML-модель нашла похожие условия в дневнике и немного усилила персональный прогноз.',
    );
  }

  Set<String> _features(WeatherRecord w) => {
    if (w.pressureDelta.abs() >= 6) 'pressure_drop',
    if (w.kpIndex >= 4)             'kp_high',
    if (w.temperatureDelta.abs() >= 7) 'temp_delta',
    if (w.humidity >= 70 || w.humidity < 30) 'humidity_high',
  };
  String _featureLabel(String f) => switch (f) {
    'pressure_drop' => 'скачки давления',
    'kp_high'       => 'магнитная активность',
    'temp_delta'    => 'перепад температуры',
    'humidity_high' => 'влажность',
    _               => f,
  };
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class ClimoShell extends StatefulWidget {
  const ClimoShell({this.enableNetwork = true, super.key});
  final bool enableNetwork;
  @override
  State<ClimoShell> createState() => _ClimoShellState();
}

class _ClimoShellState extends State<ClimoShell> {
  final _backendApi           = const BackendApiService();
  final _riskEngine           = RiskEngine();
  final _recommendationEngine = RecommendationEngine();
  final _personalRiskModel    = const PersonalRiskModel();
  final _commentController    = TextEditingController();

  var _selectedIndex = 0;
  var _wellbeing     = 7.0;
  var _sleepQuality  = 6.0;
  String? _userId;
  final _selectedSymptoms = <String>{'Головная боль'};

  UserProfile _profile = const UserProfile(
    name: 'Артем', age: 19, city: 'Москва',
    hasHypertension: false, hasHypotension: true,
    hasJointSensitivity: false, hasHeadaches: true,
    notificationsEnabled: true, notifyPressure: true,
    notifyKp: true, notifyHumidity: true, notifyTemperature: true,
    disclaimerAccepted: false,
  );

  late List<WeatherRecord> _forecast = sampleForecast();
  late List<DiaryEntry>    _diary    = [];
  var _isLoadingWeather = false;
  String? _weatherError;

  WeatherRecord get _todayWeather => _forecast.first;
  RiskResult    get _todayRisk    => _riskEngine.evaluate(_todayWeather, _profile);

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Получаем/создаём пользователя, затем параллельно грузим погоду и дневник.
  Future<void> _initUser() async {
    if (!widget.enableNetwork) {
      setState(() => _diary = sampleDiary(_riskEngine, _profile));
      return;
    }
    setState(() { _isLoadingWeather = true; _weatherError = null; });
    try {
      _userId = await _backendApi.getOrCreateUser(_profile);
      if (!mounted) return;
      await Future.wait([_loadRealWeather(), _loadDiaryFromBackend()]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _weatherError = e.toString();
        if (_diary.isEmpty) _diary = sampleDiary(_riskEngine, _profile);
      });
    }
  }

  Future<void> _loadRealWeather() async {
    setState(() { _isLoadingWeather = true; _weatherError = null; });
    try {
      final forecast = _userId != null
          ? await _backendApi.fetchForecast(_profile.city)
          : await const WeatherApiService().fetchForecast(_profile.city);
      if (!mounted) return;
      setState(() { _forecast = forecast; _isLoadingWeather = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _isLoadingWeather = false; _weatherError = error.toString(); });
    }
  }

  Future<void> _loadDiaryFromBackend() async {
    if (_userId == null) return;
    try {
      final entries = await _backendApi.loadDiaryEntries(
        _userId!, _todayWeather, _riskEngine, _profile,
      );
      if (!mounted) return;
      setState(() => _diary = entries);
    } catch (_) {
      if (_diary.isEmpty) setState(() => _diary = sampleDiary(_riskEngine, _profile));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_profile.disclaimerAccepted) {
      return _GradientBackground(
        child: DisclaimerScreen(
          onAccept: () => setState(() => _profile = _profile.copyWith(disclaimerAccepted: true)),
        ),
      );
    }

    final currentRecs = _recommendationEngine.select(recommendations, _todayRisk, _profile);

    final pages = [
      DashboardScreen(
        todayWeather: _todayWeather, risk: _todayRisk, profile: _profile,
        isLoadingWeather: _isLoadingWeather, weatherError: _weatherError,
        onRefreshWeather: widget.enableNetwork ? _loadRealWeather : null,
        onGoToDiary: () => setState(() => _selectedIndex = 3),
        onGoToRecommendations: () => setState(() => _selectedIndex = 2),
      ),
      ForecastScreen(
        forecast: _forecast, profile: _profile, riskEngine: _riskEngine,
        diary: _diary, personalRiskModel: _personalRiskModel,
      ),
      RecommendationsScreen(
        recommendations: currentRecs, allRecommendations: recommendations,
      ),
      DiaryScreen(
        wellbeing: _wellbeing, sleepQuality: _sleepQuality,
        selectedSymptoms: _selectedSymptoms, commentController: _commentController,
        entries: _diary,
        onWellbeingChanged:    (v) => setState(() => _wellbeing = v),
        onSleepQualityChanged: (v) => setState(() => _sleepQuality = v),
        onSymptomToggle: (s) => setState(() {
          _selectedSymptoms.contains(s) ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s);
        }),
        onSave: _saveDiaryEntry,
      ),
      ProfileScreen(
        profile: _profile,
        onChanged: (p) {
          final cityChanged = p.city != _profile.city;
          setState(() => _profile = p);
          // Синхронизируем профиль с беком в фоне
          if (_userId != null) {
            _backendApi.updateProfile(_userId!, p).catchError((_) {});
          }
          if (cityChanged && widget.enableNetwork) _loadRealWeather();
        },
      ),
    ];

    return _GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: ClimoTheme.blue.withValues(alpha: 0.08),
                blurRadius: 20, offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(CupertinoIcons.house), selectedIcon: Icon(CupertinoIcons.house_fill), label: 'Главная'),
              NavigationDestination(icon: Icon(CupertinoIcons.chart_bar_alt_fill), label: 'Аналитика'),
              NavigationDestination(icon: Icon(CupertinoIcons.lightbulb), selectedIcon: Icon(CupertinoIcons.lightbulb_fill), label: 'Советы'),
              NavigationDestination(icon: Icon(CupertinoIcons.book), selectedIcon: Icon(CupertinoIcons.book_fill), label: 'Дневник'),
              NavigationDestination(icon: Icon(CupertinoIcons.person), selectedIcon: Icon(CupertinoIcons.person_fill), label: 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }

  void _saveDiaryEntry() {
    final text  = _commentController.text.trim();
    final risk  = _riskEngine.evaluate(_todayWeather, _profile);
    final entry = DiaryEntry(
      time:     DateTime.now(),
      wellbeing: _wellbeing.round(),
      symptoms: _selectedSymptoms.toList(),
      comment:  text.isEmpty ? 'Самочувствие отмечено без дополнительной заметки' : text,
      weather:  _todayWeather,
      risk:     risk,
    );
    setState(() {
      _diary.insert(0, entry);
      _wellbeing = 7; _sleepQuality = 6;
      _selectedSymptoms.clear(); _commentController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Запись добавлена в дневник')),
    );
    // Сохраняем на бек в фоне; локальный список уже обновлён
    if (_userId != null) {
      _backendApi.saveDiaryEntry(_userId!, entry).catchError((_) {});
    }
  }
}

// ─── Screen 1: Disclaimer ─────────────────────────────────────────────────────

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({required this.onAccept, super.key});
  final VoidCallback onAccept;
  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  var _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: GlassCard(
                  child: Column(
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: const BoxDecoration(color: ClimoTheme.purpleLight, shape: BoxShape.circle),
                        child: const Icon(Icons.shield_outlined, color: ClimoTheme.blue, size: 38),
                      ),
                      const SizedBox(height: 20),
                      Text('Юридический дисклеймер',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      _DisclaimerItem(icon: Icons.info_outline,          text: 'Рекомендации носят информационный характер'),
                      const SizedBox(height: 12),
                      _DisclaimerItem(icon: Icons.local_hospital_outlined,text: 'Приложение не является медицинским заключением'),
                      const SizedBox(height: 12),
                      _DisclaimerItem(icon: Icons.person_outline,         text: 'Советы не заменяют консультацию врача'),
                      const SizedBox(height: 12),
                      _DisclaimerItem(icon: Icons.favorite_border,        text: 'При ухудшении состояния обратитесь к специалисту'),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Checkbox(
                            value: _accepted,
                            onChanged: (v) => setState(() => _accepted = v ?? false),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Я принимаю условия',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Понятно',
                        onPressed: _accepted ? widget.onAccept : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ClimoTheme.purpleSoft, borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClimoTheme.blue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: ClimoTheme.text)),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 2: Dashboard ──────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.todayWeather,
    required this.risk,
    required this.profile,
    required this.isLoadingWeather,
    required this.weatherError,
    required this.onRefreshWeather,
    required this.onGoToDiary,
    required this.onGoToRecommendations,
    super.key,
  });

  final WeatherRecord todayWeather;
  final RiskResult risk;
  final UserProfile profile;
  final bool isLoadingWeather;
  final String? weatherError;
  final VoidCallback? onRefreshWeather;
  final VoidCallback onGoToDiary;
  final VoidCallback onGoToRecommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              WeatherStatusCard(isLoading: isLoadingWeather, error: weatherError, onRefresh: onRefreshWeather),
              if (isLoadingWeather || weatherError != null) const SizedBox(height: 12),
              // Recommendations banner
              GestureDetector(
                onTap: onGoToRecommendations,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Рекомендации',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('Персональные советы на сегодня',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: ClimoTheme.purpleSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ClimoTheme.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Circular risk indicator
              Center(child: CircularRiskIndicator(risk: risk, city: profile.city)),
              const SizedBox(height: 24),
              // Pressure + Kp row
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: todayWeather.pressure.round().toString(),
                      unit: 'мм рт.ст.',
                      label: 'Давление',
                      icon: Icons.speed_outlined,
                      iconColor: ClimoTheme.blue,
                      iconBg: ClimoTheme.purpleLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      value: todayWeather.kpIndex.round().toString(),
                      unit: 'Kp-индекс',
                      label: 'Геомагн.',
                      icon: Icons.monitor_heart_outlined,
                      iconColor: ClimoTheme.mint,
                      iconBg: ClimoTheme.mintLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Quick action cards
              Row(
                children: [
                  Expanded(child: _ActionCard(label: 'Настройте профиль', icon: Icons.person_outline)),
                  const SizedBox(width: 14),
                  Expanded(child: _ActionCard(label: 'Пройти анкету', icon: Icons.assignment_outlined)),
                ],
              ),
              const SizedBox(height: 20),
              // Diary button
              GestureDetector(
                onTap: onGoToDiary,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      'Заполнить дневник',
                      style: TextStyle(color: Color(0xFFE53E3E), fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value, required this.unit, required this.label,
    required this.icon, required this.iconColor, required this.iconBg,
  });
  final String value, unit, label;
  final IconData icon;
  final Color iconColor, iconBg;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ClimoTheme.text, height: 1)),
          Text(unit, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: ClimoTheme.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ClimoTheme.text)),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 3: Analytics ──────────────────────────────────────────────────────

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({
    required this.forecast, required this.profile, required this.riskEngine,
    required this.diary, required this.personalRiskModel, super.key,
  });
  final List<WeatherRecord> forecast;
  final UserProfile profile;
  final RiskEngine riskEngine;
  final List<DiaryEntry> diary;
  final PersonalRiskModel personalRiskModel;
  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  var _selectedPeriod = 0;

  static const _periodDays = [7, 14, 30];

  List<DiaryEntry> get _filteredDiary {
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays[_selectedPeriod]));
    final list = widget.diary.where((e) => e.time.isAfter(cutoff)).toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final risks = widget.forecast
        .map((w) => widget.riskEngine.evaluate(w, widget.profile))
        .toList();

    final riskScores  = risks.map((r) => r.score.toDouble()).toList();
    final riskLabels  = widget.forecast.asMap().entries
        .map((e) => e.key == 0 ? 'Сег.' : formatDate(e.value.time))
        .toList();

    final filtered     = _filteredDiary;
    final diaryValues  = filtered.map((e) => e.wellbeing.toDouble()).toList();
    final diaryLabels  = filtered.map((e) => '${e.time.day}.${e.time.month}').toList();

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Text('Аналитика', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 20),

              // ── Прогноз риска на 5 дней ─────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Прогноз риска', style: Theme.of(context).textTheme.titleLarge),
                    Text('Индекс нагрузки на 5 дней вперёд',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: _ChartPainter(values: riskScores, labels: riskLabels),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    _StatsRow(values: riskScores, suffix: '/10'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 5-дневный список ────────────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Прогноз на 5 дней', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    ...List.generate(widget.forecast.length, (i) => _DayRow(
                      day:    i == 0 ? 'Сегодня' : formatDate(widget.forecast[i].time),
                      temp:   widget.forecast[i].temperature.round(),
                      risk:   risks[i],
                      isLast: i == widget.forecast.length - 1,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Переключатель периода ───────────────────────────────────
              Row(
                children: ['7 дней', '14 дней', '30 дней'].asMap().entries.map((e) {
                  final sel = e.key == _selectedPeriod;
                  return Padding(
                    padding: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? ClimoTheme.blue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                            color: sel
                                ? ClimoTheme.blue.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: sel ? 12 : 4, offset: const Offset(0, 3),
                          )],
                        ),
                        child: Text(e.value, style: TextStyle(
                          color: sel ? Colors.white : ClimoTheme.mutedText,
                          fontWeight: FontWeight.w600, fontSize: 13,
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── История самочувствия ────────────────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('История самочувствия', style: Theme.of(context).textTheme.titleLarge),
                    Text('По записям дневника', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 18),
                    if (diaryValues.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(children: [
                            Icon(Icons.book_outlined, size: 40, color: ClimoTheme.purpleLight),
                            const SizedBox(height: 10),
                            Text('Нет записей за выбранный период',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center),
                          ]),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: _ChartPainter(
                            values: diaryValues, labels: diaryLabels,
                            showDots: true, lineColor: ClimoTheme.mint,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      _StatsRow(values: diaryValues, suffix: '/10',
                          color: ClimoTheme.mint),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Analytics widgets ────────────────────────────────────────────────────────


class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.temp, required this.risk, this.isLast = false});
  final String day;
  final int temp;
  final RiskResult risk;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = riskColor(risk.level);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(child: Text(day, style: Theme.of(context).textTheme.titleMedium)),
          Text(temp > 0 ? '+$temp°' : '$temp°',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 12),
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${risk.score}/10',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.values, this.suffix = '', this.color});
  final List<double> values;
  final String suffix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final accent = color ?? ClimoTheme.blue;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          _StatCell(label: 'Минимум', value: '${min.round()}$suffix',
              color: const Color(0xFF20BD63)),
          _StatCell(label: 'Среднее',  value: '${avg.round()}$suffix', color: accent),
          _StatCell(label: 'Максимум', value: '${max.round()}$suffix',
              color: const Color(0xFFF04452)),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.values,
    required this.labels,
    this.showDots = false,
    this.lineColor,
  });
  final List<double> values;
  final List<String> labels;
  final bool showDots;
  final Color? lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const lp = 10.0, rp = 10.0, tp = 10.0, bp = 26.0;
    final chartW = size.width - lp - rp;
    final chartH = size.height - tp - bp;
    final bottom = size.height - bp;

    // Grid
    final grid = Paint()..color = ClimoTheme.purpleLight..strokeWidth = 1;
    for (final f in [0.0, 0.33, 0.66, 1.0]) {
      canvas.drawLine(Offset(lp, tp + chartH * f), Offset(size.width - rp, tp + chartH * f), grid);
    }

    // Points
    final n = values.length;
    final pts = List.generate(n, (i) {
      final x = n == 1 ? lp + chartW / 2 : lp + chartW * i / (n - 1);
      final y = bottom - chartH * (values[i] / 10).clamp(0.0, 1.0);
      return Offset(x, y);
    });

    // Smooth path
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p = pts[i - 1], c = pts[i];
      final mx = (p.dx + c.dx) / 2;
      path.cubicTo(mx, p.dy, mx, c.dy, c.dx, c.dy);
    }

    // Fill
    final fill = Path.from(path)
      ..lineTo(pts.last.dx, bottom)..lineTo(pts.first.dx, bottom)..close();
    final baseColor = lineColor ?? ClimoTheme.blue;
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [baseColor.withValues(alpha: 0.18), baseColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(lp, tp, chartW, chartH)));

    // Line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    if (lineColor != null) {
      linePaint.color = lineColor!;
    } else {
      linePaint.shader = const LinearGradient(
        colors: [Color(0xFF20BD63), Color(0xFFD59300), Color(0xFFF04452)],
      ).createShader(Rect.fromLTWH(lp, tp, chartW, chartH));
    }
    canvas.drawPath(path, linePaint);

    // Dots
    if (showDots) {
      for (final pt in pts) {
        canvas.drawCircle(pt, 5, Paint()..color = baseColor);
        canvas.drawCircle(pt, 5,
            Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }

    // Labels
    final tp2 = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < pts.length; i++) {
      if (i >= labels.length) break;
      if (n > 7 && i % 2 != 0) continue;
      tp2.text = TextSpan(text: labels[i],
          style: const TextStyle(color: ClimoTheme.mutedText, fontSize: 10));
      tp2.layout();
      tp2.paint(canvas, Offset(pts[i].dx - tp2.width / 2, bottom + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.values != values || old.showDots != showDots || old.lineColor != lineColor;
}

// ─── Screen 4: Diary ──────────────────────────────────────────────────────────

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({
    required this.wellbeing,
    required this.sleepQuality,
    required this.selectedSymptoms,
    required this.commentController,
    required this.entries,
    required this.onWellbeingChanged,
    required this.onSleepQualityChanged,
    required this.onSymptomToggle,
    required this.onSave,
    super.key,
  });

  final double wellbeing;
  final double sleepQuality;
  final Set<String> selectedSymptoms;
  final TextEditingController commentController;
  final List<DiaryEntry> entries;
  final ValueChanged<double> onWellbeingChanged;
  final ValueChanged<double> onSleepQualityChanged;
  final ValueChanged<String> onSymptomToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              // Wellbeing section
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Общее самочувствие', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    EmojiScale(value: wellbeing),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: GradientSlider(value: wellbeing, onChanged: onWellbeingChanged)),
                        const SizedBox(width: 12),
                        ScoreCircle(score: wellbeing.round()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Sleep quality section
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Качество сна', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    EmojiScale(value: sleepQuality),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: GradientSlider(value: sleepQuality, onChanged: onSleepQualityChanged)),
                        const SizedBox(width: 12),
                        ScoreCircle(score: sleepQuality.round()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Symptoms
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Конкретные симптомы', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: diarySymptoms.map((s) {
                        final isSel = selectedSymptoms.contains(s);
                        return GestureDetector(
                          onTap: () => onSymptomToggle(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? ClimoTheme.blue : Colors.transparent,
                              border: Border.all(
                                color: isSel ? ClimoTheme.blue : ClimoTheme.purpleLight,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                  color: isSel ? Colors.white : ClimoTheme.mutedText,
                                  fontSize: 14, fontWeight: FontWeight.w500,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(label: 'Зафиксировать состояние', onPressed: onSave),
              const SizedBox(height: 24),
              ...entries.map(DiaryEntryCard.new),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Screen: Recommendations ──────────────────────────────────────────────────

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({
    required this.recommendations, required this.allRecommendations, super.key,
  });
  final List<RecommendationItem> recommendations;
  final List<RecommendationItem> allRecommendations;

  @override
  Widget build(BuildContext context) {
    final grouped = <RecommendationCategory, List<RecommendationItem>>{};
    for (final item in allRecommendations) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Text('Рекомендации', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              Text('Персональные советы на сегодня', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              const NoticeCard(),
              const SizedBox(height: 20),
              RecommendationGroupCard(
                category: RecommendationCategory.activity,
                items: recommendations.where((i) => i.category == RecommendationCategory.activity).take(3).toList(),
              ),
              const SizedBox(height: 16),
              RecommendationGroupCard(
                category: RecommendationCategory.nutrition,
                items: grouped[RecommendationCategory.nutrition]!.take(3).toList(),
              ),
              const SizedBox(height: 16),
              RecommendationGroupCard(
                category: RecommendationCategory.routine,
                items: grouped[RecommendationCategory.routine]!.take(3).toList(),
              ),
              const SizedBox(height: 16),
              RecommendationGroupCard(
                category: RecommendationCategory.control,
                items: grouped[RecommendationCategory.control]!.take(2).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Screen: Profile ──────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.profile, required this.onChanged, super.key});
  final UserProfile profile;
  final ValueChanged<UserProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Text('Профиль', style: Theme.of(context).textTheme.displaySmall),
              Text('${profile.city}, ${profile.age} лет', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Профиль помогает мягче настраивать пороги риска и тексты уведомлений.',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    ProfileSwitch(title: 'Гипотония', subtitle: 'Чувствительность к снижению давления.', value: profile.hasHypotension, onChanged: (v) => onChanged(profile.copyWith(hasHypotension: v))),
                    ProfileSwitch(title: 'Гипертония', subtitle: 'Чувствительность к скачкам давления.', value: profile.hasHypertension, onChanged: (v) => onChanged(profile.copyWith(hasHypertension: v))),
                    ProfileSwitch(title: 'Головные боли', subtitle: 'Учитывать давление и Kp-индекс.', value: profile.hasHeadaches, onChanged: (v) => onChanged(profile.copyWith(hasHeadaches: v))),
                    ProfileSwitch(title: 'Уведомления', subtitle: 'Предупреждать о желтом и красном риске.', value: profile.notificationsEnabled, onChanged: (v) => onChanged(profile.copyWith(notificationsEnabled: v))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SoftWarningCard(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared UI Widgets ────────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [ClimoTheme.gradientTop, ClimoTheme.gradientBot],
        ),
      ),
      child: child,
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            color: ClimoTheme.text, onPressed: () {},
          ),
          const Expanded(
            child: Text(
              'МетеоДневник',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: ClimoTheme.text),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({required this.child, this.padding = const EdgeInsets.all(22), super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ClimoTheme.blue.withValues(alpha: 0.07),
            blurRadius: 28, spreadRadius: 0, offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 4, spreadRadius: -2, offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// kept for backward compat
class ClimoCard extends StatelessWidget {
  const ClimoCard({required this.child, this.padding = const EdgeInsets.all(22), super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => GlassCard(padding: padding, child: child);
}

class AppScrollView extends StatelessWidget {
  const AppScrollView({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 28), children: [child]);
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : ClimoTheme.purpleLight,
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [BoxShadow(
                    color: ClimoTheme.blue.withValues(alpha: 0.32),
                    blurRadius: 16, offset: const Offset(0, 6),
                  )]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : ClimoTheme.mutedText,
                fontSize: 17, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircularRiskIndicator extends StatelessWidget {
  const CircularRiskIndicator({required this.risk, required this.city, super.key});
  final RiskResult risk;
  final String city;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 168, height: 168,
          child: CustomPaint(
            painter: _RiskRingPainter(score: risk.score),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('RISK',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: ClimoTheme.mutedText, letterSpacing: 2.5,
                      )),
                  const SizedBox(height: 2),
                  Text('${risk.score}',
                      style: const TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w700,
                        color: ClimoTheme.text, height: 1.0,
                      )),
                  const Text('/10',
                      style: TextStyle(fontSize: 13, color: ClimoTheme.mutedText)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 15, color: ClimoTheme.blue),
            const SizedBox(width: 4),
            Text(city,
                style: const TextStyle(fontSize: 14, color: ClimoTheme.mutedText, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Text(risk.level.label,
            style: TextStyle(
              color: riskColor(risk.level), fontSize: 13, fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _RiskRingPainter extends CustomPainter {
  const _RiskRingPainter({required this.score});
  final int score;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const stroke = 13.0;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * score / 10;

    canvas.drawCircle(center, radius,
        Paint()..color = ClimoTheme.purpleLight..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);

    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect, startAngle, sweepAngle, false,
        Paint()
          ..shader = SweepGradient(
            startAngle: startAngle, endAngle: startAngle + sweepAngle,
            colors: const [Color(0xFF8B5CF6), Color(0xFF93C5FD)],
            tileMode: TileMode.clamp,
          ).createShader(rect)
          ..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _RiskRingPainter old) => old.score != score;
}

class EmojiScale extends StatelessWidget {
  const EmojiScale({required this.value, super.key});
  final double value;
  static const _emojis = ['😭', '😞', '😐', '🙂', '😄'];
  int get _activeIdx {
    if (value <= 2) return 0;
    if (value <= 4) return 1;
    if (value <= 6) return 2;
    if (value <= 8) return 3;
    return 4;
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _emojis.asMap().entries.map((e) {
        final isActive = e.key == _activeIdx;
        return AnimatedScale(
          scale: isActive ? 1.3 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(e.value, style: TextStyle(fontSize: isActive ? 32 : 24)),
        );
      }).toList(),
    );
  }
}

class GradientSlider extends StatelessWidget {
  const GradientSlider({required this.value, required this.onChanged, super.key});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackShape: _GradientTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13, elevation: 5),
      ),
      child: Slider(min: 1, max: 10, value: value, onChanged: onChanged),
    );
  }
}

class _GradientTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox, Offset offset = Offset.zero,
    required SliderThemeData sliderTheme, bool isEnabled = false, bool isDiscrete = false,
  }) {
    final h = sliderTheme.trackHeight ?? 8;
    return Rect.fromLTWH(
      offset.dx + 16, offset.dy + (parentBox.size.height - h) / 2,
      parentBox.size.width - 32, h,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset, {
    required RenderBox parentBox, required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation, required Offset thumbCenter,
    Offset? secondaryOffset, bool isEnabled = false, bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(parentBox: parentBox, offset: offset,
        sliderTheme: sliderTheme, isEnabled: isEnabled, isDiscrete: isDiscrete);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF04452), Color(0xFFD59300), Color(0xFF20BD63)],
        ).createShader(rect),
    );
  }
}

class ScoreCircle extends StatelessWidget {
  const ScoreCircle({required this.score, super.key});
  final int score;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: ClimoTheme.blue.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text('$score',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Misc Widgets ─────────────────────────────────────────────────────────────

class WeatherStatusCard extends StatelessWidget {
  const WeatherStatusCard({required this.isLoading, required this.error, required this.onRefresh, super.key});
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && error == null) return const SizedBox.shrink();
    final hasError = error != null;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: ClimoTheme.blue))
          else
            Icon(Icons.cloud_off_outlined, color: hasError ? const Color(0xFFD96B62) : ClimoTheme.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading ? 'Загружаю данные Open-Meteo и NOAA SWPC...'
                        : 'Не удалось обновить погоду. Показаны демо-данные. $error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (hasError && onRefresh != null)
            TextButton(
              onPressed: onRefresh, style: TextButton.styleFrom(foregroundColor: ClimoTheme.blue),
              child: const Text('Повторить'),
            ),
        ],
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD89A00), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Все рекомендации носят информационный характер и не заменяют консультацию врача.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationGroupCard extends StatelessWidget {
  const RecommendationGroupCard({required this.category, required this.items, super.key});
  final RecommendationCategory category;
  final List<RecommendationItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = recommendationPalette(category);
    final visible = items.isEmpty
        ? recommendations.where((i) => i.category == category).take(3).toList()
        : items;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: palette.background, borderRadius: BorderRadius.circular(16)),
                child: Icon(category.icon, color: palette.foreground, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(category.title, style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 18),
          ...visible.map((item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(color: palette.pill, borderRadius: BorderRadius.circular(16)),
            child: Text(item.text, style: Theme.of(context).textTheme.bodyLarge),
          )),
        ],
      ),
    );
  }
}

class DiaryEntryCard extends StatelessWidget {
  const DiaryEntryCard(this.entry, {super.key});
  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final pal = diaryColor(entry.wellbeing);
    final icon = entry.wellbeing >= 7 ? Icons.sentiment_satisfied_alt
        : entry.wellbeing >= 5 ? Icons.sentiment_neutral
        : Icons.sentiment_dissatisfied;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pal.background, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pal.border, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatLongDate(entry.time), style: Theme.of(context).textTheme.titleLarge),
                    Text(formatTime(entry.time), style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              Icon(icon, color: pal.icon, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: entry.symptoms.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text(s, style: const TextStyle(fontSize: 14, color: ClimoTheme.text)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Text(entry.comment, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class ProfileSwitch extends StatelessWidget {
  const ProfileSwitch({required this.title, required this.subtitle, required this.value, required this.onChanged, super.key});
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      value: value, onChanged: onChanged,
      activeThumbColor: ClimoTheme.blue,
    );
  }
}

class SoftWarningCard extends StatelessWidget {
  const SoftWarningCard({super.key});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        'Приложение не ставит диагнозы и не назначает лечение. Любые лекарства принимайте только по назначению врача.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

// ─── Palette helpers ──────────────────────────────────────────────────────────

class Palette {
  const Palette({required this.foreground, required this.background, required this.pill});
  final Color foreground, background, pill;
}

class DiaryPalette {
  const DiaryPalette({required this.background, required this.border, required this.icon});
  final Color background, border, icon;
}

Palette recommendationPalette(RecommendationCategory cat) => switch (cat) {
  RecommendationCategory.activity  => const Palette(foreground: Color(0xFF7C3AED), background: Color(0xFFEDE9FE), pill: Color(0xFFF5F3FF)),
  RecommendationCategory.nutrition => const Palette(foreground: Color(0xFF10B981), background: Color(0xFFD1FAE5), pill: Color(0xFFECFDF5)),
  RecommendationCategory.routine   => const Palette(foreground: Color(0xFF2563EB), background: Color(0xFFDBEAFE), pill: Color(0xFFEFF6FF)),
  RecommendationCategory.control   => const Palette(foreground: Color(0xFFE71635), background: Color(0xFFFFF1F2), pill: Color(0xFFFFF5F5)),
};

DiaryPalette diaryColor(int w) {
  if (w >= 7) return const DiaryPalette(background: Color(0xFFF1FFF6), border: Color(0xFFB8F2C9), icon: Color(0xFF24C56B));
  if (w >= 5) return const DiaryPalette(background: Color(0xFFFFFDEB), border: Color(0xFFFFF28A), icon: Color(0xFFE8B100));
  return const DiaryPalette(background: Color(0xFFFFF1F2), border: Color(0xFFFFC9CF), icon: Color(0xFFF04452));
}

Color riskColor(RiskLevel l) => switch (l) {
  RiskLevel.low    => const Color(0xFF20BD63),
  RiskLevel.medium => const Color(0xFFD59300),
  RiskLevel.high   => const Color(0xFFF04452),
};

// ─── Formatting ───────────────────────────────────────────────────────────────

String formatDate(DateTime d) => '${d.day} ${months[d.month - 1]}';
String formatLongDate(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
String formatTime(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

const months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];

// ─── Sample Data ──────────────────────────────────────────────────────────────

List<WeatherRecord> sampleForecast() {
  final now = DateTime.now();
  return [
    WeatherRecord(time: now, temperature: 18, temperatureDelta: 4, pressure: 752, pressureDelta: 8, humidity: 48, windSpeed: 4.2, kpIndex: 3, source: 'Демо-данные'),
    WeatherRecord(time: now.add(const Duration(days: 1)), temperature: 16, temperatureDelta: -8, pressure: 744, pressureDelta: -7, humidity: 58, windSpeed: 5.1, kpIndex: 4, source: 'Демо-данные'),
    WeatherRecord(time: now.add(const Duration(days: 2)), temperature: 12, temperatureDelta: -11, pressure: 732, pressureDelta: -14, humidity: 84, windSpeed: 10.1, kpIndex: 5, source: 'Демо-данные'),
    WeatherRecord(time: now.add(const Duration(days: 3)), temperature: 19, temperatureDelta: 7, pressure: 747, pressureDelta: 5, humidity: 57, windSpeed: 4.4, kpIndex: 3, source: 'Демо-данные'),
    WeatherRecord(time: now.add(const Duration(days: 4)), temperature: 22, temperatureDelta: 3, pressure: 750, pressureDelta: 2, humidity: 49, windSpeed: 3.8, kpIndex: 2, source: 'Демо-данные'),
  ];
}

List<DiaryEntry> sampleDiary(RiskEngine riskEngine, UserProfile profile) {
  final weather = sampleForecast().first;
  final risk    = riskEngine.evaluate(weather, profile);
  return [
    DiaryEntry(time: DateTime(2026, 5, 4, 20, 30), wellbeing: 8, symptoms: const ['Головная боль'], comment: 'Чувствую себя хорошо, небольшая головная боль после работы', weather: weather, risk: risk),
    DiaryEntry(time: DateTime(2026, 5, 3, 10, 15), wellbeing: 5, symptoms: const ['Усталость', 'Сонливость'], comment: 'Плохо спала ночью, весь день сонная', weather: weather, risk: risk),
    DiaryEntry(time: DateTime(2026, 5, 2, 18, 00), wellbeing: 3, symptoms: const ['Головная боль', 'Головокружение'], comment: 'Тяжелая голова, лучше помогли тишина и отдых', weather: weather, risk: risk),
  ];
}

const diarySymptoms = [
  'Головная боль', 'Головокружение', 'Сонливость', 'Боль в суставах',
  'Шум в ушах', 'Тревога', 'Слабость', 'Мигрень',
];

// kept for backward compat (used by DiaryEntryCard symptom chips)
const symptoms = [
  'Головная боль', 'Сонливость', 'Усталость', 'Боль в суставах',
  'Перепады давления', 'Головокружение', 'Слабость', 'Тревожность',
];

const recommendations = [
  RecommendationItem(id: 1,  category: RecommendationCategory.activity,  text: 'Замените утреннюю пробежку на десятиминутную растяжку дома',                   tags: {'pressure_drop','kp_high','temp_delta'}, profiles: {}, priority: 80),
  RecommendationItem(id: 2,  category: RecommendationCategory.activity,  text: 'Избегайте длительной ходьбы при перепадах влажности',                           tags: {'humidity_high','temp_delta'},           profiles: {}, priority: 75),
  RecommendationItem(id: 3,  category: RecommendationCategory.activity,  text: 'Ограничьте кардиотренировки в дни магнитных бурь',                               tags: {'kp_high'},                              profiles: {}, priority: 70),
  RecommendationItem(id: 4,  category: RecommendationCategory.nutrition, text: 'В дни перепадов давления лучше заменить кофе на травяной чай',                   tags: {'pressure_drop'},                        profiles: {}, priority: 90),
  RecommendationItem(id: 5,  category: RecommendationCategory.nutrition, text: 'Выпейте стакан воды прямо сейчас и еще один через два часа',                     tags: {'humidity_high','pressure_drop'},        profiles: {}, priority: 85),
  RecommendationItem(id: 6,  category: RecommendationCategory.nutrition, text: 'Уберите жирное, жареное и сладкое в дни геомагнитных бурь',                      tags: {'kp_high'},                              profiles: {}, priority: 70),
  RecommendationItem(id: 7,  category: RecommendationCategory.routine,   text: 'Регулярно проветривайте помещение краткими интервалами',                          tags: {'humidity_high','normal'},               profiles: {}, priority: 65),
  RecommendationItem(id: 8,  category: RecommendationCategory.routine,   text: 'Лягте спать на полчаса раньше при ожидании магнитной бури',                      tags: {'kp_high'},                              profiles: {}, priority: 75),
  RecommendationItem(id: 9,  category: RecommendationCategory.routine,   text: 'Поддерживайте в спальне температуру около 18-20 градусов',                       tags: {'temp_delta','normal'},                  profiles: {}, priority: 60),
  RecommendationItem(id: 10, category: RecommendationCategory.control,   text: 'Обратите внимание на артериальное давление утром и вечером',                      tags: {'pressure_drop'},                        profiles: {'profile_hypertension','profile_hypotension'}, priority: 95),
  RecommendationItem(id: 11, category: RecommendationCategory.control,   text: 'Лекарства принимайте только по назначению врача',                                tags: {'pressure_drop','kp_high','temp_delta'}, profiles: {}, priority: 100),
  RecommendationItem(id: 12, category: RecommendationCategory.activity,  text: 'День спокойный: сохраняйте обычный мягкий режим',                                tags: {'normal'},                               profiles: {}, priority: 10),
];
