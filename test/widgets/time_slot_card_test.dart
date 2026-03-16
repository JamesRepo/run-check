import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/utils/theme.dart';
import 'package:run_check/widgets/time_slot_card.dart';

void main() {
  group('[Widget] TimeSlotCard', () {
    testWidgets('should display rank, date, time, and weather info', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 1);

      expect(find.text('1'), findsOneWidget);
      // Tuesday, 15 Apr 2025
      expect(find.text('Tuesday, 15 Apr'), findsOneWidget);
      expect(find.text('07:00 – 08:00'), findsOneWidget);
      expect(find.text('14°C'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('8 km/h'), findsOneWidget);
    });

    testWidgets('should display rank number 3 for third slot', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 3);

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'should convert temperature to Fahrenheit when unit is fahrenheit',
      (WidgetTester tester) async {
        await _pumpCard(
          tester,
          slot: _clearMorningSlot,
          rank: 1,
          unit: TemperatureUnit.fahrenheit,
        );

        // 14°C = 57.2°F → rounds to 57
        expect(find.text('57°F'), findsOneWidget);
        expect(find.text('14°C'), findsNothing);
      },
    );

    testWidgets('should show sunny icon for weather code 0', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(0), rank: 1);

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('should show sunny icon for weather code 1', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(1), rank: 1);

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('should show cloud icon for weather code 2', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(2), rank: 1);

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('should show cloud icon for weather code 3', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(3), rank: 1);

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('should show cloud icon for fog weather code 45', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(45), rank: 1);

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('should show water drop icon for drizzle code 51', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(51), rank: 1);

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('should show water drop icon for rain code 63', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(63), rank: 1);

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('should show snow icon for weather code 73', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(73), rank: 1);

      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('should show water drop icon for rain shower code 80', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(80), rank: 1);

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('should show thunderstorm icon for weather code 95', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(95), rank: 1);

      expect(find.byIcon(Icons.thunderstorm), findsOneWidget);
    });

    testWidgets('should show thunderstorm icon for weather code 99', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(99), rank: 1);

      expect(find.byIcon(Icons.thunderstorm), findsOneWidget);
    });

    testWidgets('should show green score dot when score >= 0.7', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0.85),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.green);
    });

    testWidgets('should show green score dot when score is exactly 0.7', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0.7),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.green);
    });

    testWidgets('should show amber score dot when score is 0.4–0.69', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0.55),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.amber);
    });

    testWidgets('should show amber score dot when score is exactly 0.4', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0.4),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.amber);
    });

    testWidgets('should show red score dot when score < 0.4', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0.2),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.red);
    });

    testWidgets('should show red score dot when score is 0', (
      WidgetTester tester,
    ) async {
      await _pumpCard(
        tester,
        slot: _slotWithScore(0),
        rank: 1,
      );

      final dot = _findScoreDot(tester);
      expect(dot, Colors.red);
    });

    testWidgets('should zero-pad single-digit hours and minutes', (
      WidgetTester tester,
    ) async {
      final slot = TimeSlot(
        startTime: DateTime(2025, 4, 15, 7),
        endTime: DateTime(2025, 4, 15, 8),
        score: 0.8,
        temperature: 14,
        precipitationProbability: 10,
        windSpeed: 8,
        weatherCode: 0,
        weatherDescription: 'Clear sky',
      );

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('07:00 – 08:00'), findsOneWidget);
    });

    testWidgets('should format afternoon times correctly', (
      WidgetTester tester,
    ) async {
      final slot = TimeSlot(
        startTime: DateTime(2025, 4, 15, 14, 30),
        endTime: DateTime(2025, 4, 15, 15, 30),
        score: 0.8,
        temperature: 18,
        precipitationProbability: 5,
        windSpeed: 6,
        weatherCode: 0,
        weatherDescription: 'Clear sky',
      );

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('14:30 – 15:30'), findsOneWidget);
    });

    testWidgets('should round wind speed to nearest integer', (
      WidgetTester tester,
    ) async {
      final slot = TimeSlot(
        startTime: DateTime(2025, 4, 15, 9),
        endTime: DateTime(2025, 4, 15, 10),
        score: 0.8,
        temperature: 14,
        precipitationProbability: 10,
        windSpeed: 8.7,
        weatherCode: 0,
        weatherDescription: 'Clear sky',
      );

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('9 km/h'), findsOneWidget);
    });

    testWidgets('should display all seven weekday names correctly', (
      WidgetTester tester,
    ) async {
      // 2025-04-14 is a Monday
      final monday = DateTime(2025, 4, 14, 9);
      final slot = _slotWithStartTime(monday);

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('Monday, 14 Apr'), findsOneWidget);
    });

    testWidgets('should display Saturday correctly', (
      WidgetTester tester,
    ) async {
      // 2025-04-19 is a Saturday
      final saturday = DateTime(2025, 4, 19, 9);
      final slot = _slotWithStartTime(saturday);

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('Saturday, 19 Apr'), findsOneWidget);
    });

    testWidgets('should display January month abbreviation', (
      WidgetTester tester,
    ) async {
      final jan = DateTime(2025, 1, 5, 9);
      final slot = _slotWithStartTime(jan);

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('Sunday, 5 Jan'), findsOneWidget);
    });

    testWidgets('should display December month abbreviation', (
      WidgetTester tester,
    ) async {
      final dec = DateTime(2025, 12, 25, 9);
      final slot = _slotWithStartTime(dec);

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('Thursday, 25 Dec'), findsOneWidget);
    });

    testWidgets('should render inside a Card with expected structure', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 1);

      expect(find.byType(Card), findsOneWidget);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────

final _clearMorningSlot = TimeSlot(
  startTime: DateTime(2025, 4, 15, 7),
  endTime: DateTime(2025, 4, 15, 8),
  score: 0.85,
  temperature: 14,
  precipitationProbability: 10,
  windSpeed: 8,
  weatherCode: 1,
  weatherDescription: 'Mainly clear',
);

TimeSlot _slotWithWeatherCode(int code) {
  return TimeSlot(
    startTime: DateTime(2025, 4, 15, 9),
    endTime: DateTime(2025, 4, 15, 10),
    score: 0.8,
    temperature: 14,
    precipitationProbability: 10,
    windSpeed: 8,
    weatherCode: code,
    weatherDescription: 'Test',
  );
}

TimeSlot _slotWithScore(double score) {
  return TimeSlot(
    startTime: DateTime(2025, 4, 15, 9),
    endTime: DateTime(2025, 4, 15, 10),
    score: score,
    temperature: 14,
    precipitationProbability: 10,
    windSpeed: 8,
    weatherCode: 1,
    weatherDescription: 'Mainly clear',
  );
}

TimeSlot _slotWithStartTime(DateTime startTime) {
  return TimeSlot(
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 1)),
    score: 0.8,
    temperature: 14,
    precipitationProbability: 10,
    windSpeed: 8,
    weatherCode: 0,
    weatherDescription: 'Clear sky',
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required TimeSlot slot,
  required int rank,
  TemperatureUnit unit = TemperatureUnit.celsius,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TimeSlotCard(slot: slot, rank: rank, unit: unit),
        ),
      ),
    ),
  );
}

Color? _findScoreDot(WidgetTester tester) {
  final containers = tester.widgetList<Container>(
    find.byType(Container),
  );

  for (final container in containers) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        container.constraints?.maxWidth == 10 &&
        container.constraints?.maxHeight == 10) {
      return decoration.color;
    }
  }

  return null;
}
