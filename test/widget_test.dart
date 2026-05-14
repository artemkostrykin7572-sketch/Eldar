import 'package:climo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Climo opens dashboard and switches tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClimoApp(enableNetwork: false));

    expect(find.text('Здравствуйте!'), findsOneWidget);
    expect(find.text('Индекс благополучия'), findsOneWidget);
    expect(find.text('Факторы влияния'), findsOneWidget);

    await tester.tap(find.text('Прогноз'));
    await tester.pumpAndSettle();

    expect(find.text('График на сегодня'), findsOneWidget);
    expect(find.text('Прогноз на 5 дней'), findsOneWidget);
    expect(find.text('ML-прогноз'), findsOneWidget);

    await tester.tap(find.text('Советы'));
    await tester.pumpAndSettle();

    expect(find.text('Рекомендации'), findsOneWidget);
    expect(find.text('Физическая активность'), findsOneWidget);

    await tester.tap(find.text('Дневник'));
    await tester.pumpAndSettle();

    expect(find.text('Новая запись'), findsOneWidget);
    expect(find.text('3 мая 2026'), findsOneWidget);
  });

  test('Risk engine marks combined triggers as high risk', () {
    final profile = UserProfile(
      name: 'Тест',
      age: 30,
      city: 'Москва',
      hasHypertension: true,
      hasHypotension: false,
      hasJointSensitivity: false,
      hasHeadaches: true,
      notificationsEnabled: true,
      notifyPressure: true,
      notifyKp: true,
      notifyHumidity: true,
      notifyTemperature: true,
      disclaimerAccepted: true,
    );
    final weather = WeatherRecord(
      time: DateTime(2026, 5, 4),
      temperature: 8,
      temperatureDelta: -11,
      pressure: 731,
      pressureDelta: -13,
      humidity: 80,
      windSpeed: 5,
      kpIndex: 5,
      source: 'test',
    );

    final risk = RiskEngine().evaluate(weather, profile);

    expect(risk.level, RiskLevel.high);
    expect(risk.reasons, contains('давление'));
    expect(risk.reasons, contains('геомагнитная активность'));
  });

  test('Personal risk model raises score for known diary trigger', () {
    final profile = UserProfile(
      name: 'Тест',
      age: 30,
      city: 'Москва',
      hasHypertension: false,
      hasHypotension: true,
      hasJointSensitivity: false,
      hasHeadaches: true,
      notificationsEnabled: true,
      notifyPressure: true,
      notifyKp: true,
      notifyHumidity: true,
      notifyTemperature: true,
      disclaimerAccepted: true,
    );
    final riskEngine = RiskEngine();
    final weather = WeatherRecord(
      time: DateTime(2026, 5, 12),
      temperature: 16,
      temperatureDelta: -2,
      pressure: 738,
      pressureDelta: -8,
      humidity: 50,
      windSpeed: 4,
      kpIndex: 2,
      source: 'test',
    );
    final baseRisk = riskEngine.evaluate(weather, profile);
    final diary = [
      DiaryEntry(
        time: DateTime(2026, 5, 1),
        wellbeing: 4,
        symptoms: const ['Головная боль'],
        comment: 'Плохо при скачке давления',
        weather: weather,
        risk: baseRisk,
      ),
      DiaryEntry(
        time: DateTime(2026, 5, 2),
        wellbeing: 5,
        symptoms: const ['Усталость'],
        comment: 'Снова давление',
        weather: weather,
        risk: baseRisk,
      ),
      DiaryEntry(
        time: DateTime(2026, 5, 3),
        wellbeing: 8,
        symptoms: const [],
        comment: 'Норма',
        weather: weather.copyWithPressureDelta(0),
        risk: riskEngine.evaluate(weather.copyWithPressureDelta(0), profile),
      ),
    ];

    final prediction = const PersonalRiskModel().predict(
      diary: diary,
      weather: weather,
      baseRisk: baseRisk,
    );

    expect(prediction.adjustment, greaterThan(0));
    expect(prediction.triggers, contains('скачки давления'));
  });
}

extension on WeatherRecord {
  WeatherRecord copyWithPressureDelta(double pressureDelta) {
    return WeatherRecord(
      time: time,
      temperature: temperature,
      temperatureDelta: temperatureDelta,
      pressure: pressure,
      pressureDelta: pressureDelta,
      humidity: humidity,
      windSpeed: windSpeed,
      kpIndex: kpIndex,
      source: source,
    );
  }
}
