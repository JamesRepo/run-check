import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/services/run_scheduler.dart';

/// Creates a [HourlyForecast] with sensible defaults for testing.
/// Override individual fields as needed.
HourlyForecast _forecast({
  required DateTime dateTime,
  double temperature = 15,
  int precipitationProbability = 10,
  double windSpeed = 8,
  double humidity = 50,
  int weatherCode = 0,
}) {
  return HourlyForecast(
    dateTime: dateTime,
    temperature: temperature,
    precipitationProbability: precipitationProbability,
    windSpeed: windSpeed,
    humidity: humidity,
    weatherCode: weatherCode,
  );
}

/// Generates a list of hourly forecasts spanning consecutive
/// hours starting at [start]. Each hour gets the same defaults
/// unless overridden.
List<HourlyForecast> _generateForecasts({
  required DateTime start,
  required int count,
  double temperature = 15,
  int precipitationProbability = 10,
  double windSpeed = 8,
  double humidity = 50,
  int weatherCode = 0,
}) {
  return List.generate(
    count,
    (i) => _forecast(
      dateTime: start.add(Duration(hours: i)),
      temperature: temperature,
      precipitationProbability: precipitationProbability,
      windSpeed: windSpeed,
      humidity: humidity,
      weatherCode: weatherCode,
    ),
  );
}

void main() {
  const scheduler = RunScheduler();

  // ── tempScore ─────────────────────────────────────────

  group('[Unit] RunScheduler.tempScore', () {
    test('should return 1.0 when temperature is in the '
        'ideal range (12–18°C)', () {
      expect(RunScheduler.tempScore(12), 1.0);
      expect(RunScheduler.tempScore(15), 1.0);
      expect(RunScheduler.tempScore(18), 1.0);
    });

    test('should return 0.0 when temperature is at or '
        'below 0°C', () {
      expect(RunScheduler.tempScore(0), 0.0);
      expect(RunScheduler.tempScore(-1), 0.0);
      expect(RunScheduler.tempScore(-20), 0.0);
    });

    test('should return 0.0 when temperature is above '
        '35°C', () {
      expect(RunScheduler.tempScore(35.1), 0.0);
      expect(RunScheduler.tempScore(40), 0.0);
    });

    test('should taper linearly between 0°C and 12°C', () {
      expect(RunScheduler.tempScore(6), closeTo(0.5, 0.001));
      expect(RunScheduler.tempScore(3), closeTo(0.25, 0.001));
      expect(RunScheduler.tempScore(9), closeTo(0.75, 0.001));
    });

    test('should taper linearly between 18°C and 35°C', () {
      // (35 - 26.5) / (35 - 18) = 8.5 / 17 = 0.5
      expect(RunScheduler.tempScore(26.5), closeTo(0.5, 0.001));
      expect(RunScheduler.tempScore(35), closeTo(0.0, 0.001));
    });

    test('should return exactly 0.0 at the boundary of '
        '35°C', () {
      // At exactly 35: (35 - 35) / (35 - 18) = 0.0
      expect(RunScheduler.tempScore(35), 0.0);
    });
  });

  // ── precipScore ───────────────────────────────────────

  group('[Unit] RunScheduler.precipScore', () {
    test('should return 1.0 when probability is 0', () {
      expect(RunScheduler.precipScore(0), 1.0);
    });

    test('should return 0.0 when probability is 100', () {
      expect(RunScheduler.precipScore(100), 0.0);
    });

    test('should return 0.5 when probability is 50', () {
      expect(RunScheduler.precipScore(50), 0.5);
    });

    test('should clamp negative probability to 0', () {
      expect(RunScheduler.precipScore(-10), 1.0);
    });

    test('should clamp probability above 100 to 1', () {
      expect(RunScheduler.precipScore(150), 0.0);
    });

    test('should scale linearly between 0 and 100', () {
      expect(RunScheduler.precipScore(25), closeTo(0.75, 0.001));
      expect(RunScheduler.precipScore(75), closeTo(0.25, 0.001));
    });
  });

  // ── windScore ─────────────────────────────────────────

  group('[Unit] RunScheduler.windScore', () {
    test('should return 1.0 when wind is at or below '
        '10 km/h', () {
      expect(RunScheduler.windScore(0), 1.0);
      expect(RunScheduler.windScore(5), 1.0);
      expect(RunScheduler.windScore(10), 1.0);
    });

    test('should return 0.0 when wind is at or above '
        '40 km/h', () {
      expect(RunScheduler.windScore(40), 0.0);
      expect(RunScheduler.windScore(50), 0.0);
    });

    test('should taper linearly between 10 and 40 km/h',
        () {
      // (25 - 10) / (40 - 10) = 15/30 = 0.5
      expect(RunScheduler.windScore(25), closeTo(0.5, 0.001));
      expect(
        RunScheduler.windScore(17.5),
        closeTo(0.75, 0.001),
      );
    });
  });

  // ── humidityScore ─────────────────────────────────────

  group('[Unit] RunScheduler.humidityScore', () {
    test('should return 1.0 when humidity is at or below '
        '60%', () {
      expect(RunScheduler.humidityScore(0), 1.0);
      expect(RunScheduler.humidityScore(30), 1.0);
      expect(RunScheduler.humidityScore(60), 1.0);
    });

    test('should return 0.0 when humidity is at or above '
        '90%', () {
      expect(RunScheduler.humidityScore(90), 0.0);
      expect(RunScheduler.humidityScore(100), 0.0);
    });

    test('should taper linearly between 60% and 90%', () {
      // (75 - 60) / (90 - 60) = 15/30 = 0.5
      expect(
        RunScheduler.humidityScore(75),
        closeTo(0.5, 0.001),
      );
      expect(
        RunScheduler.humidityScore(67.5),
        closeTo(0.75, 0.001),
      );
    });
  });

  // ── findBestSlots: edge cases ─────────────────────────

  group('[Unit] RunScheduler.findBestSlots edge cases', () {
    test('should return empty list when numberOfRuns '
        'is zero', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 5,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 0,
      );

      expect(result, isEmpty);
    });

    test('should return empty list when numberOfRuns '
        'is negative', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 5,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: -1,
      );

      expect(result, isEmpty);
    });

    test('should return empty list when forecasts is '
        'empty', () {
      final result = scheduler.findBestSlots(
        forecasts: const [],
        numberOfRuns: 3,
      );

      expect(result, isEmpty);
    });

    test('should return fewer slots than requested when '
        'not enough valid windows exist', () {
      // Only 2 hours, both morning, asking for 3 runs
      // with 12-hour spacing — at most 1 can be selected.
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 2,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 3,
      );

      expect(result.length, lessThan(3));
      expect(result, isNotEmpty);
    });

    test('should return empty list when all forecasts fall '
        'outside preferred periods', () {
      // 2 AM — outside all default periods
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 2),
        count: 3,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, isEmpty);
    });

    test('should still return slots when all scores are '
        'terrible', () {
      // Temperature 40 (score 0), precip 100% (score 0),
      // wind 50 (score 0), humidity 95 (score 0).
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 3,
        temperature: 40,
        precipitationProbability: 100,
        windSpeed: 50,
        humidity: 95,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.score, 0.0);
    });
  });

  // ── findBestSlots: period filtering ───────────────────

  group('[Unit] RunScheduler.findBestSlots period filtering',
      () {
    test('should only include morning hours (05–11) when '
        'preferredPeriods is morning', () {
      // Generate 24 hours starting at midnight
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16),
        count: 24,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        preferredPeriods: const ['morning'],
      );

      for (final slot in result) {
        expect(slot.startTime.hour, inInclusiveRange(5, 11));
      }
    });

    test('should only include afternoon hours (12–17) when '
        'preferredPeriods is afternoon', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16),
        count: 24,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        preferredPeriods: const ['afternoon'],
      );

      for (final slot in result) {
        expect(
          slot.startTime.hour,
          inInclusiveRange(12, 17),
        );
      }
    });

    test('should only include evening hours (18–21) when '
        'preferredPeriods is evening', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16),
        count: 24,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        preferredPeriods: const ['evening'],
      );

      for (final slot in result) {
        expect(
          slot.startTime.hour,
          inInclusiveRange(18, 21),
        );
      }
    });

    test('should include both morning and evening hours '
        'when both periods are selected', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16),
        count: 24,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        preferredPeriods: const ['morning', 'evening'],
      );

      for (final slot in result) {
        final h = slot.startTime.hour;
        expect(
          h >= 5 && h <= 11 || h >= 18 && h <= 21,
          isTrue,
          reason: 'Hour $h should be morning or evening',
        );
      }
    });

    test('should ignore unrecognised period names', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 5,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        preferredPeriods: const ['midnight'],
      );

      expect(result, isEmpty);
    });
  });

  // ── findBestSlots: sunrise/sunset filtering ───────────

  group(
      '[Unit] RunScheduler.findBestSlots sunrise/sunset '
      'filtering', () {
    test('should exclude hours before sunrise when sunData '
        'is provided', () {
      // Sunrise at 07:30 — hour 05, 06, 07 should be excluded
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 5),
        count: 7, // 05:00 to 11:00
      );

      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 16),
          sunrise: DateTime(2026, 3, 16, 7, 30),
          sunset: DateTime(2026, 3, 16, 18, 30),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        preferredPeriods: const ['morning'],
        sunData: sunData,
      );

      for (final slot in result) {
        expect(
          slot.startTime.hour,
          greaterThanOrEqualTo(8),
          reason: 'Should not include hours before sunrise',
        );
      }
    });

    test('should exclude hours after sunset when sunData '
        'is provided', () {
      // Sunset at 18:30 — hours 19, 20, 21 should be excluded
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 17),
        count: 6, // 17:00 to 22:00
      );

      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 16),
          sunrise: DateTime(2026, 3, 16, 6),
          sunset: DateTime(2026, 3, 16, 18, 30),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        sunData: sunData,
      );

      for (final slot in result) {
        expect(
          slot.startTime.hour,
          lessThanOrEqualTo(18),
          reason: 'Should not include hours after sunset',
        );
      }
    });

    test('should keep hours that fall exactly at sunrise',
        () {
      final sunrise = DateTime(2026, 3, 16, 8);
      final forecasts = [
        _forecast(dateTime: sunrise), // exactly at sunrise
      ];

      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 16),
          sunrise: sunrise,
          sunset: DateTime(2026, 3, 16, 18),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        sunData: sunData,
      );

      expect(result, hasLength(1));
    });

    test('should keep hours that fall exactly at sunset',
        () {
      final sunset = DateTime(2026, 3, 16, 18);
      final forecasts = [
        _forecast(dateTime: sunset),
      ];

      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 16),
          sunrise: DateTime(2026, 3, 16, 6),
          sunset: sunset,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        sunData: sunData,
      );

      expect(result, hasLength(1));
    });

    test('should not apply sun filtering when sunData is '
        'null', () {
      // 05:00 — before typical sunrise, but no sunData
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 5),
        count: 3,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, isNotEmpty);
    });

    test('should allow hours when sunData exists but has '
        'no entry for that day', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 5),
        count: 3,
      );

      // Sun data for a different day
      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 17),
          sunrise: DateTime(2026, 3, 17, 8),
          sunset: DateTime(2026, 3, 17, 18),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        sunData: sunData,
      );

      expect(result, isNotEmpty);
    });
  });

  // ── findBestSlots: multi-hour windows ─────────────────

  group('[Unit] RunScheduler.findBestSlots multi-hour '
      'windows', () {
    test('should create 1-hour windows for a 60-minute '
        'run', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 3,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
      final slot = result.first;
      expect(
        slot.endTime.difference(slot.startTime),
        const Duration(hours: 1),
      );
    });

    test('should create 2-hour windows for a 90-minute '
        'run', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 4,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        runDurationMinutes: 90,
      );

      expect(result, hasLength(1));
      final slot = result.first;
      expect(
        slot.endTime.difference(slot.startTime),
        const Duration(hours: 2),
      );
    });

    test('should create 2-hour windows for a 120-minute '
        'run', () {
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 8),
        count: 4,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        runDurationMinutes: 120,
      );

      expect(result, hasLength(1));
      final slot = result.first;
      expect(
        slot.endTime.difference(slot.startTime),
        const Duration(hours: 2),
      );
    });

    test('should skip windows with non-consecutive hours',
        () {
      // Hours 08, 09, 11 (gap at 10) — no valid 2-hour
      // window starting at 09.
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 8)),
        _forecast(dateTime: DateTime(2026, 3, 16, 9)),
        _forecast(dateTime: DateTime(2026, 3, 16, 11)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 10,
        runDurationMinutes: 120,
      );

      // Only [08, 09] is consecutive for 2 hours
      expect(result, hasLength(1));
      expect(result.first.startTime.hour, 8);
    });

    test('should return empty list when run duration '
        'exceeds available consecutive hours', () {
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 8)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        runDurationMinutes: 120,
      );

      expect(result, isEmpty);
    });

    test('should average metrics across multi-hour '
        'windows', () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 8),
          temperature: 10,
          precipitationProbability: 20,
          windSpeed: 5,
          humidity: 40,
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          temperature: 20,
          precipitationProbability: 40,
          windSpeed: 15,
          humidity: 80,
          weatherCode: 3,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        runDurationMinutes: 120,
      );

      expect(result, hasLength(1));
      final slot = result.first;
      expect(slot.temperature, 15); // avg(10, 20)
      expect(slot.precipitationProbability, 30); // avg(20, 40)
      expect(slot.windSpeed, 10); // avg(5, 15)
    });

    test('should use the worst weather code in a '
        'multi-hour window', () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 8),
          weatherCode: 1, // Mainly clear
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          weatherCode: 61, // Slight rain
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
        runDurationMinutes: 120,
      );

      expect(result, hasLength(1));
      expect(result.first.weatherCode, 61);
      expect(
        result.first.weatherDescription,
        'Slight rain',
      );
    });
  });

  // ── findBestSlots: scoring ────────────────────────────

  group('[Unit] RunScheduler.findBestSlots scoring', () {
    test('should assign higher score to better weather '
        'conditions', () {
      // Good conditions at 09:00
      final good = _forecast(
        dateTime: DateTime(2026, 3, 16, 9),
        precipitationProbability: 5,
        windSpeed: 5,
        humidity: 45,
      );
      // Bad conditions at 10:00 (same day, within gap)
      // but on a different day to avoid spacing issues
      final bad = _forecast(
        dateTime: DateTime(2026, 3, 17, 9),
        temperature: 35,
        precipitationProbability: 80,
        windSpeed: 35,
        humidity: 85,
      );

      final result = scheduler.findBestSlots(
        forecasts: [good, bad],
        numberOfRuns: 2,
      );

      expect(result, hasLength(2));
      // The good slot should have a higher score
      final goodSlot = result.firstWhere(
        (s) => s.startTime.day == 16,
      );
      final badSlot = result.firstWhere(
        (s) => s.startTime.day == 17,
      );
      expect(goodSlot.score, greaterThan(badSlot.score));
    });

    test('should produce a score of 1.0 with perfect '
        'conditions', () {
      // temp 15 (ideal), precip 0, wind 5 (calm),
      // humidity 50 (comfortable)
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          precipitationProbability: 0,
          windSpeed: 5,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.score, closeTo(1.0, 0.001));
    });

    test('should produce a score of 0.0 with worst '
        'conditions', () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          temperature: -5,
          precipitationProbability: 100,
          windSpeed: 50,
          humidity: 95,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.score, closeTo(0.0, 0.001));
    });

    test('should weight precipitation highest in the '
        'score', () {
      // Two slots: one with bad precip, one with bad temp.
      // Precip weight (0.35) > temp weight (0.30), so bad
      // precip should produce a lower score.
      final badPrecip = _forecast(
        dateTime: DateTime(2026, 3, 16, 9),
        precipitationProbability: 100, // worst
        windSpeed: 5,
      );
      final badTemp = _forecast(
        dateTime: DateTime(2026, 3, 17, 9),
        temperature: -5, // worst
        precipitationProbability: 0, // perfect
        windSpeed: 5,
      );

      final result = scheduler.findBestSlots(
        forecasts: [badPrecip, badTemp],
        numberOfRuns: 2,
      );

      final precipSlot = result.firstWhere(
        (s) => s.startTime.day == 16,
      );
      final tempSlot = result.firstWhere(
        (s) => s.startTime.day == 17,
      );

      // Bad precip should score lower because precip
      // weight (0.35) > temp weight (0.30)
      expect(precipSlot.score, lessThan(tempSlot.score));
    });
  });

  // ── findBestSlots: spacing ────────────────────────────

  group('[Unit] RunScheduler.findBestSlots spacing', () {
    test('should skip slots within 12 hours of an already '
        'selected slot', () {
      // Two slots 2 hours apart, same day — only the
      // better one should be selected.
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 8),
          precipitationProbability: 5,
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 16, 10),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 2,
      );

      // Can only select 1 because they're within 12h
      expect(result, hasLength(1));
    });

    test('should select slots on different days when '
        'spaced more than 12 hours', () {
      // Day 1 morning and Day 2 morning — 24h apart
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 9)),
        _forecast(dateTime: DateTime(2026, 3, 17, 9)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 2,
      );

      expect(result, hasLength(2));
    });

    test('should allow morning and evening on the same day '
        'when gap is >= 12 hours', () {
      // 06:00 and 19:00 same day — 13 hours apart
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 6)),
        _forecast(dateTime: DateTime(2026, 3, 16, 19)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 2,
      );

      expect(result, hasLength(2));
    });

    test('should not allow morning and afternoon on the '
        'same day when gap is < 12 hours', () {
      // 09:00 and 15:00 same day — 6 hours apart
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 9)),
        _forecast(dateTime: DateTime(2026, 3, 16, 15)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 2,
      );

      expect(result, hasLength(1));
    });

    test('should prefer higher-scored slot when two are '
        'within the gap', () {
      // Both at 09:00 and 10:00 — within 12h.
      // 09:00 has better conditions.
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          precipitationProbability: 0,
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 16, 10),
          precipitationProbability: 50,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.startTime.hour, 9);
    });
  });

  // ── findBestSlots: output ordering & fields ───────────

  group(
      '[Unit] RunScheduler.findBestSlots output ordering '
      'and fields', () {
    test('should return slots sorted chronologically', () {
      // Provide several days of data. The best-scoring
      // slot might be on day 3, but output should be
      // ordered by start time.
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 18, 9),
          precipitationProbability: 0,
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          precipitationProbability: 5,
        ),
        _forecast(
          dateTime: DateTime(2026, 3, 17, 9),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 3,
      );

      expect(result, hasLength(3));
      expect(result[0].startTime.day, 16);
      expect(result[1].startTime.day, 17);
      expect(result[2].startTime.day, 18);
    });

    test('should set endTime to startTime + 1 hour for '
        'single-hour slots', () {
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 9)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result.first.startTime, DateTime(2026, 3, 16, 9));
      expect(
        result.first.endTime,
        DateTime(2026, 3, 16, 10),
      );
    });

    test('should populate weatherDescription from the '
        'constants map', () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          weatherCode: 3,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result.first.weatherDescription, 'Overcast');
    });

    test('should use "Unknown" for unmapped weather '
        'codes', () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          weatherCode: 999,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result.first.weatherDescription, 'Unknown');
    });

    test('should populate all TimeSlot fields correctly',
        () {
      final forecasts = [
        _forecast(
          dateTime: DateTime(2026, 3, 16, 9),
          weatherCode: 2,
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      final slot = result.first;
      expect(slot.startTime, DateTime(2026, 3, 16, 9));
      expect(slot.endTime, DateTime(2026, 3, 16, 10));
      expect(slot.score, greaterThan(0));
      expect(slot.temperature, 15);
      expect(slot.precipitationProbability, 10);
      expect(slot.windSpeed, 8);
      expect(slot.weatherCode, 2);
      expect(slot.weatherDescription, 'Partly cloudy');
    });
  });

  // ── findBestSlots: integration-style scenarios ────────

  group(
      '[Unit] RunScheduler.findBestSlots realistic '
      'scenarios', () {
    test('should pick the 3 best-spaced slots from a '
        'week of mixed weather', () {
      final forecasts = <HourlyForecast>[];

      // Day 1: great morning
      for (var h = 5; h <= 11; h++) {
        forecasts.add(
          _forecast(
            dateTime: DateTime(2026, 3, 16, h),
            precipitationProbability: 5,
          ),
        );
      }
      // Day 2: rainy all day
      for (var h = 5; h <= 21; h++) {
        forecasts.add(
          _forecast(
            dateTime: DateTime(2026, 3, 17, h),
            temperature: 10,
            precipitationProbability: 80,
            windSpeed: 20,
            humidity: 85,
            weatherCode: 63,
          ),
        );
      }
      // Day 3: nice evening
      for (var h = 18; h <= 21; h++) {
        forecasts.add(
          _forecast(
            dateTime: DateTime(2026, 3, 18, h),
            temperature: 16,
            windSpeed: 5,
            humidity: 55,
            weatherCode: 1,
          ),
        );
      }
      // Day 4: decent afternoon
      for (var h = 12; h <= 17; h++) {
        forecasts.add(
          _forecast(
            dateTime: DateTime(2026, 3, 19, h),
            temperature: 14,
            precipitationProbability: 20,
            windSpeed: 12,
            humidity: 60,
            weatherCode: 2,
          ),
        );
      }

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 3,
      );

      expect(result, hasLength(3));

      // Should be chronologically sorted
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].startTime.isAfter(result[i - 1].startTime),
          isTrue,
        );
      }

      // Day 1 morning should be the highest-scoring
      final bestSlot = [...result]
        ..sort((a, b) => b.score.compareTo(a.score));
      expect(bestSlot.first.startTime.day, 16);
    });

    test('should handle single forecast for a single run '
        'request', () {
      final forecasts = [
        _forecast(dateTime: DateTime(2026, 3, 16, 10)),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 1,
      );

      expect(result, hasLength(1));
    });

    test('should handle 90-minute run with sunrise '
        'filtering', () {
      // Hours 05–11, but sunrise at 07:15
      // Valid start times for 2-hour windows: 08, 09, 10
      // (07 is before sunrise, 11 would need 12 which
      //  doesn't exist)
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16, 5),
        count: 7, // 05 through 11
      );

      final sunData = [
        SunriseSunset(
          date: DateTime(2026, 3, 16),
          sunrise: DateTime(2026, 3, 16, 7, 15),
          sunset: DateTime(2026, 3, 16, 18, 30),
        ),
      ];

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 5,
        runDurationMinutes: 90,
        preferredPeriods: const ['morning'],
        sunData: sunData,
      );

      for (final slot in result) {
        expect(slot.startTime.hour, greaterThanOrEqualTo(8));
        expect(
          slot.endTime.difference(slot.startTime),
          const Duration(hours: 2),
        );
      }
    });

    test('should return multiple consecutive days with '
        'default all-period filtering', () {
      // 3 days of full 24-hour forecasts
      final forecasts = _generateForecasts(
        start: DateTime(2026, 3, 16),
        count: 72,
      );

      final result = scheduler.findBestSlots(
        forecasts: forecasts,
        numberOfRuns: 3,
      );

      expect(result, hasLength(3));

      // Each should be on a different day or well-spaced
      for (var i = 1; i < result.length; i++) {
        final gap = result[i]
            .startTime
            .difference(result[i - 1].startTime)
            .inHours;
        expect(gap, greaterThanOrEqualTo(12));
      }
    });
  });
}
