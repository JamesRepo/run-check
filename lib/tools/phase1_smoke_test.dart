import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/services/run_scheduler.dart';

typedef ForecastFetcher =
    Future<WeatherResult> Function(double lat, double lng);

typedef LineWriter = void Function(String line);

class Phase1SmokeTestRunner {
  const Phase1SmokeTestRunner({
    required this.fetchForecast,
    required this.hadFreshCache,
    this.scheduler = const RunScheduler(),
    this.output = _noopWriter,
    this.errorOutput = _noopWriter,
  });

  final ForecastFetcher fetchForecast;
  final bool hadFreshCache;
  final RunScheduler scheduler;
  final LineWriter output;
  final LineWriter errorOutput;

  static const northamptonLat = 52.2405;
  static const northamptonLng = -0.9027;

  Future<int> run() async {
    try {
      final weatherResult = await fetchForecast(northamptonLat, northamptonLng);

      final threeRunSlots = scheduler.findBestSlots(
        forecasts: weatherResult.hourlyForecasts,
        numberOfRuns: 3,
        sunData: weatherResult.dailySunData,
      );
      final morningOnlySlots = scheduler.findBestSlots(
        forecasts: weatherResult.hourlyForecasts,
        numberOfRuns: 5,
        preferredPeriods: const ['morning'],
        sunData: weatherResult.dailySunData,
      );
      final sevenRunSlots = scheduler.findBestSlots(
        forecasts: weatherResult.hourlyForecasts,
        numberOfRuns: 7,
        sunData: weatherResult.dailySunData,
      );
      final source = describeSource(
        hadFreshCache: hadFreshCache,
        isStale: weatherResult.isStale,
      );

      output('=== Phase 1 Integration Smoke Test ===');
      output('Location: Northampton, UK (52.2405, -0.9027)');
      output(
        'Weather data: ${weatherResult.hourlyForecasts.length} hourly points',
      );
      output('Source: $source');
      output('');
      output('=== Best Slots: 3 Runs, All Periods ===');
      _printSlots(threeRunSlots);
      output('');
      output('=== Best Slots: 5 Runs, Morning Only ===');
      _printSlots(morningOnlySlots);
      output('');
      output('=== Best Slots: 7 Runs, Full Week ===');
      _printSlots(sevenRunSlots);
      output('');
      output('=== Phase 1 Status ===');
      output(
        '✓ Weather API: connected, '
        '${weatherResult.hourlyForecasts.length} hours of data',
      );
      output('✓ Algorithm: returned ${threeRunSlots.length} slots for 3 runs');
      output(
        '✓ Morning-only filter: returned '
        '${morningOnlySlots.length} slots for 5 runs',
      );
      output('✓ Full week: returned ${sevenRunSlots.length} slots for 7 runs');

      return 0;
    } on Object catch (error) {
      errorOutput('Phase 1 smoke test failed.');
      errorOutput(
        'Unable to fetch weather data or run the scheduler. '
        'Check your internet connection and try again.',
      );
      errorOutput('Details: $error');
      return 1;
    }
  }

  void _printSlots(List<TimeSlot> slots) {
    if (slots.isEmpty) {
      output('No matching slots found.');
      return;
    }

    for (var index = 0; index < slots.length; index++) {
      output('Slot ${index + 1}: ${formatSlot(slots[index])}');
    }
  }
}

String describeSource({required bool hadFreshCache, required bool isStale}) {
  if (isStale) {
    return 'cache (stale fallback)';
  }

  if (hadFreshCache) {
    return 'cache (fresh)';
  }

  return 'live API';
}

String formatSlot(TimeSlot slot) {
  final date = slot.startTime;

  return '${weekdayName(date.weekday)} ${date.day} '
      '${monthName(date.month)}, '
      '${formatTime(slot.startTime)}–${formatTime(slot.endTime)} '
      '— ${slot.temperature.round()}°C, '
      '${slot.precipitationProbability}% rain, '
      '${slot.windSpeed.round()} km/h wind '
      '— Score: ${slot.score.toStringAsFixed(2)}';
}

String formatTime(DateTime dateTime) {
  final hours = dateTime.hour.toString().padLeft(2, '0');
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String weekdayName(int weekday) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdays[weekday - 1];
}

String monthName(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

void _noopWriter(String _) {}
