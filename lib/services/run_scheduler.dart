import 'dart:math';

import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/utils/constants.dart';

/// Finds optimal running time slots from weather forecast data.
///
/// Pure Dart logic — no API calls, no side effects, no Flutter
/// dependencies.
class RunScheduler {
  const RunScheduler();

  static const _periodRanges = <String, (int, int)>{
    'morning': (5, 11),
    'afternoon': (12, 17),
    'evening': (18, 21),
  };

  static const _minGapHours = 12;

  /// Returns up to [numberOfRuns] optimal [TimeSlot]s sorted
  /// chronologically.
  List<TimeSlot> findBestSlots({
    required List<HourlyForecast> forecasts,
    required int numberOfRuns,
    int runDurationMinutes = 60,
    List<String> preferredPeriods = const [
      'morning',
      'afternoon',
      'evening',
    ],
    List<SunriseSunset>? sunData,
  }) {
    if (numberOfRuns <= 0 || forecasts.isEmpty) {
      return const [];
    }

    // Step 1 — Filter by preferred periods and daylight.
    final filtered = _filterForecasts(
      forecasts,
      preferredPeriods,
      sunData,
    );
    if (filtered.isEmpty) return const [];

    // Step 2 — Build multi-hour windows.
    final hoursNeeded = (runDurationMinutes / 60).ceil();
    final windows = _buildWindows(filtered, hoursNeeded);
    if (windows.isEmpty) return const [];

    // Step 3 — Score each window.
    final scored = windows
        .map(
          (w) => _ScoredWindow(
            window: w,
            score: _scoreWindow(w),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Step 4 — Greedy spaced selection.
    // Step 5 — Return in chronological order.
    final selected = _selectWithSpacing(scored, numberOfRuns)
      ..sort(
        (a, b) => a.window.first.dateTime.compareTo(
          b.window.first.dateTime,
        ),
      );

    return selected.map(_toTimeSlot).toList();
  }

  // ── Sub-scores (public + static for unit testing) ───────

  /// 1.0 between 12–18 °C. Linear taper to 0.0 at 0 °C /
  /// 35 °C. Outside that range returns 0.0.
  static double tempScore(double temperature) {
    const idealLow = 12.0;
    const idealHigh = 18.0;
    const absLow = 0.0;
    const absHigh = 35.0;

    if (temperature >= idealLow && temperature <= idealHigh) {
      return 1;
    }
    if (temperature < absLow || temperature > absHigh) {
      return 0;
    }
    if (temperature < idealLow) {
      return (temperature - absLow) / (idealLow - absLow);
    }
    return (absHigh - temperature) / (absHigh - idealHigh);
  }

  /// 1.0 at 0 % probability, 0.0 at 100 %.
  static double precipScore(
    double precipitationProbability,
  ) {
    return 1.0 -
        (precipitationProbability / 100).clamp(0.0, 1.0);
  }

  /// 1.0 at ≤ 10 km/h. Linear taper to 0.0 at 40 km/h.
  static double windScore(double windSpeedKmh) {
    const calm = 10.0;
    const limit = 40.0;

    if (windSpeedKmh <= calm) return 1;
    if (windSpeedKmh >= limit) return 0;
    return 1.0 - (windSpeedKmh - calm) / (limit - calm);
  }

  /// 1.0 at ≤ 60 %. Linear taper to 0.0 at 90 %.
  /// [humidity] is a percentage (0–100).
  static double humidityScore(double humidity) {
    const comfortHigh = 60.0;
    const ceiling = 90.0;

    if (humidity <= comfortHigh) return 1;
    if (humidity >= ceiling) return 0;
    return 1.0 -
        (humidity - comfortHigh) / (ceiling - comfortHigh);
  }

  // ── Private helpers ─────────────────────────────────────

  List<HourlyForecast> _filterForecasts(
    List<HourlyForecast> forecasts,
    List<String> preferredPeriods,
    List<SunriseSunset>? sunData,
  ) {
    final allowedHours = <int>{};
    for (final period in preferredPeriods) {
      final range = _periodRanges[period];
      if (range != null) {
        for (var h = range.$1; h <= range.$2; h++) {
          allowedHours.add(h);
        }
      }
    }

    final sunMap = <DateTime, SunriseSunset>{};
    if (sunData != null) {
      for (final sd in sunData) {
        final key = DateTime(
          sd.date.year,
          sd.date.month,
          sd.date.day,
        );
        sunMap[key] = sd;
      }
    }

    return forecasts.where((f) {
      if (!allowedHours.contains(f.dateTime.hour)) {
        return false;
      }

      if (sunData != null) {
        final day = DateTime(
          f.dateTime.year,
          f.dateTime.month,
          f.dateTime.day,
        );
        final sd = sunMap[day];
        if (sd != null &&
            (f.dateTime.isBefore(sd.sunrise) ||
                f.dateTime.isAfter(sd.sunset))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<List<HourlyForecast>> _buildWindows(
    List<HourlyForecast> filtered,
    int hoursNeeded,
  ) {
    if (hoursNeeded <= 0 ||
        filtered.length < hoursNeeded) {
      return const [];
    }

    final windows = <List<HourlyForecast>>[];

    for (var i = 0; i <= filtered.length - hoursNeeded; i++) {
      final window = filtered.sublist(i, i + hoursNeeded);

      var consecutive = true;
      for (var j = 1; j < window.length; j++) {
        final gap = window[j]
            .dateTime
            .difference(window[j - 1].dateTime);
        if (gap != const Duration(hours: 1)) {
          consecutive = false;
          break;
        }
      }

      if (consecutive) windows.add(window);
    }

    return windows;
  }

  double _scoreWindow(List<HourlyForecast> window) {
    final n = window.length;
    final avgTemp = window
            .map((h) => h.temperature)
            .reduce((a, b) => a + b) /
        n;
    final avgPrecip = window
            .map((h) => h.precipitationProbability)
            .reduce((a, b) => a + b) /
        n;
    final avgWind = window
            .map((h) => h.windSpeed)
            .reduce((a, b) => a + b) /
        n;
    final avgHumidity = window
            .map((h) => h.humidity)
            .reduce((a, b) => a + b) /
        n;

    return precipitationWeight * precipScore(avgPrecip) +
        temperatureWeight * tempScore(avgTemp) +
        windWeight * windScore(avgWind) +
        humidityWeight * humidityScore(avgHumidity);
  }

  List<_ScoredWindow> _selectWithSpacing(
    List<_ScoredWindow> sorted,
    int numberOfRuns,
  ) {
    final selected = <_ScoredWindow>[];

    for (final candidate in sorted) {
      if (selected.length >= numberOfRuns) break;

      final start = candidate.window.first.dateTime;
      final tooClose = selected.any((s) {
        final diff = start
            .difference(s.window.first.dateTime)
            .inHours
            .abs();
        return diff < _minGapHours;
      });

      if (!tooClose) selected.add(candidate);
    }

    return selected;
  }

  TimeSlot _toTimeSlot(_ScoredWindow entry) {
    final window = entry.window;
    final n = window.length;

    final avgTemp = window
            .map((h) => h.temperature)
            .reduce((a, b) => a + b) /
        n;
    final avgPrecip = window
            .map((h) => h.precipitationProbability)
            .reduce((a, b) => a + b) /
        n;
    final avgWind = window
            .map((h) => h.windSpeed)
            .reduce((a, b) => a + b) /
        n;
    final worstCode =
        window.map((h) => h.weatherCode).reduce(max);

    return TimeSlot(
      startTime: window.first.dateTime,
      endTime: window.last.dateTime.add(
        const Duration(hours: 1),
      ),
      score: entry.score,
      temperature: avgTemp,
      precipitationProbability: avgPrecip.round(),
      windSpeed: avgWind,
      weatherCode: worstCode,
      weatherDescription:
          weatherCodeDescriptions[worstCode] ?? 'Unknown',
    );
  }
}

class _ScoredWindow {
  const _ScoredWindow({
    required this.window,
    required this.score,
  });

  final List<HourlyForecast> window;
  final double score;
}
