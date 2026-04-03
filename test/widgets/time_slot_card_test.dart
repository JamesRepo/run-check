import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_shadows.dart';
import 'package:run_check/utils/app_spacing.dart';
import 'package:run_check/utils/theme.dart';
import 'package:run_check/widgets/time_slot_card.dart';

void main() {
  group('[Widget] TimeSlotCard', () {
    testWidgets('should display rank, date, time, and weather info', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 1);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Tuesday, 15 Apr'), findsOneWidget);
      expect(find.text('07:00 – 08:00'), findsOneWidget);
      expect(find.text('14°C'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('8 km/h'), findsOneWidget);
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

        expect(find.text('57°F'), findsOneWidget);
        expect(find.text('14°C'), findsNothing);
      },
    );

    testWidgets('should use a sunny icon when the weather code is clear', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(1), rank: 1);

      final icon = tester.widget<Icon>(find.byIcon(Icons.wb_sunny));
      expect(icon.color, AppColors.sunnyIcon);
    });

    testWidgets('should use a cloudy icon when the weather code is cloudy', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(3), rank: 1);

      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud));
      expect(icon.color, AppColors.cloudyIcon);
    });

    testWidgets('should use a rain icon when the weather code is wet', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _slotWithWeatherCode(63), rank: 1);

      final icon = tester.widget<Icon>(find.byIcon(Icons.water_drop));
      expect(icon.color, AppColors.rainIcon);
    });

    testWidgets(
      'should render the result card with editorial shadow and white surface',
      (WidgetTester tester) async {
        await _pumpCard(tester, slot: _clearMorningSlot, rank: 1);

        final decoratedBox = tester.widget<DecoratedBox>(
          find.byType(DecoratedBox).first,
        );
        final decoration = decoratedBox.decoration as BoxDecoration;

        expect(decoration.color, AppColors.surfaceContainerLowest);
        expect(decoration.borderRadius, BorderRadius.circular(AppRadii.card));
        expect(decoration.boxShadow, const <BoxShadow>[
          AppShadows.editorialShadow,
        ]);
      },
    );

    testWidgets('should render the rank badge with primary fill when shown', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 3);

      final badge = tester.widget<Container>(_findRankBadge());
      final decoration = badge.decoration! as BoxDecoration;

      expect(badge.constraints?.maxWidth, 40);
      expect(badge.constraints?.maxHeight, 40);
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, appTheme.colorScheme.primary);
    });

    testWidgets('should render weather metrics inside tonal data pills', (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, slot: _clearMorningSlot, rank: 1);

      final pillFinder = find.ancestor(
        of: find.text('14°C'),
        matching: find.byType(Container),
      );
      final pill = tester.widgetList<Container>(pillFinder).firstWhere((pill) {
        final decoration = pill.decoration;
        return decoration is BoxDecoration &&
            decoration.color == AppColors.surfaceContainerLow;
      });

      final decoration = pill.decoration! as BoxDecoration;

      expect(
        pill.padding,
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.dataPillPaddingH,
          vertical: AppSpacing.dataPillPaddingV,
        ),
      );
      expect(decoration.borderRadius, BorderRadius.circular(AppRadii.dataPill));
    });

    testWidgets(
      'should render an excellent score strip when the score is at least 0.7',
      (WidgetTester tester) async {
        await _pumpCard(tester, slot: _slotWithScore(0.7), rank: 1);

        final strip = tester.widget<Container>(_findScoreStrip());
        expect(strip.color, AppColors.scoreExcellent);
      },
    );

    testWidgets(
      'should render a fair score strip when the score is between 0.4 and 0.69',
      (WidgetTester tester) async {
        await _pumpCard(tester, slot: _slotWithScore(0.55), rank: 1);

        final strip = tester.widget<Container>(_findScoreStrip());
        expect(strip.color, AppColors.scoreFair);
      },
    );

    testWidgets(
      'should render a poor score strip when the score is below 0.4',
      (WidgetTester tester) async {
        await _pumpCard(tester, slot: _slotWithScore(0.2), rank: 1);

        final strip = tester.widget<Container>(_findScoreStrip());
        expect(strip.color, AppColors.scorePoor);
      },
    );

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

    testWidgets('should format afternoon times correctly when rendered', (
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

    testWidgets('should round wind speed to the nearest integer', (
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

    testWidgets('should display weekday and month abbreviations correctly', (
      WidgetTester tester,
    ) async {
      final slot = _slotWithStartTime(DateTime(2025, 12, 25, 9));

      await _pumpCard(tester, slot: slot, rank: 1);

      expect(find.text('Thursday, 25 Dec'), findsOneWidget);
    });
  });
}

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

Finder _findRankBadge() {
  return find.byWidgetPredicate((Widget widget) {
    if (widget is! Container) {
      return false;
    }

    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == appTheme.colorScheme.primary;
  });
}

Finder _findScoreStrip() {
  return find.byWidgetPredicate((Widget widget) {
    return widget is Container &&
        widget.constraints?.minHeight == 6 &&
        widget.constraints?.maxHeight == 6;
  });
}
