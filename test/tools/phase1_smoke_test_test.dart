import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/services/run_scheduler.dart';
import 'package:run_check/tools/phase1_smoke_test.dart';

class _SchedulerCall {
  const _SchedulerCall({
    required this.numberOfRuns,
    required this.preferredPeriods,
    required this.forecasts,
    required this.sunData,
  });

  final int numberOfRuns;
  final List<String> preferredPeriods;
  final List<HourlyForecast> forecasts;
  final List<SunriseSunset>? sunData;
}

class _FakeRunScheduler extends RunScheduler {
  _FakeRunScheduler(this.responses);

  final Map<int, List<TimeSlot>> responses;
  final calls = <_SchedulerCall>[];

  @override
  List<TimeSlot> findBestSlots({
    required List<HourlyForecast> forecasts,
    required int numberOfRuns,
    int runDurationMinutes = 60,
    List<String> preferredPeriods = const ['morning', 'afternoon', 'evening'],
    List<SunriseSunset>? sunData,
  }) {
    calls.add(
      _SchedulerCall(
        numberOfRuns: numberOfRuns,
        preferredPeriods: preferredPeriods,
        forecasts: forecasts,
        sunData: sunData,
      ),
    );

    return responses[numberOfRuns] ?? const [];
  }
}

WeatherResult _weatherResult({bool isStale = false}) {
  final forecasts = <HourlyForecast>[
    HourlyForecast(
      dateTime: DateTime(2026, 3, 16, 7),
      temperature: 12,
      precipitationProbability: 10,
      windSpeed: 8,
      humidity: 55,
      weatherCode: 1,
    ),
    HourlyForecast(
      dateTime: DateTime(2026, 3, 16, 8),
      temperature: 13,
      precipitationProbability: 5,
      windSpeed: 9,
      humidity: 58,
      weatherCode: 1,
    ),
  ];
  final sunData = <SunriseSunset>[
    SunriseSunset(
      date: DateTime(2026, 3, 16),
      sunrise: DateTime(2026, 3, 16, 6, 15),
      sunset: DateTime(2026, 3, 16, 18, 10),
    ),
  ];

  return WeatherResult(
    forecast: ForecastResponse(
      latitude: Phase1SmokeTestRunner.northamptonLat,
      longitude: Phase1SmokeTestRunner.northamptonLng,
      timezone: 'Europe/London',
      hourlyForecasts: forecasts,
      dailySunData: sunData,
      isStale: isStale,
    ),
    isStale: isStale,
  );
}

TimeSlot _slot({
  required DateTime startTime,
  double temperature = 14,
  int precipitationProbability = 10,
  double windSpeed = 8,
  double score = 0.87,
}) {
  return TimeSlot(
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 1)),
    score: score,
    temperature: temperature,
    precipitationProbability: precipitationProbability,
    windSpeed: windSpeed,
    weatherCode: 1,
    weatherDescription: 'Mainly clear',
  );
}

void main() {
  group('[Unit] phase1 smoke test formatting', () {
    test('should describe stale fallback source when result is stale', () {
      expect(
        describeSource(hadFreshCache: true, isStale: true),
        'cache (stale fallback)',
      );
    });

    test('should describe fresh cache source '
        'when cache exists and result is fresh', () {
      expect(
        describeSource(hadFreshCache: true, isStale: false),
        'cache (fresh)',
      );
    });

    test('should describe live api source when no cache exists', () {
      expect(describeSource(hadFreshCache: false, isStale: false), 'live API');
    });

    test('should format a slot in the human-readable smoke test format '
        'when slot details are provided', () {
      final slot = _slot(
        startTime: DateTime(2026, 4, 15, 7),
        temperature: 14.2,
        windSpeed: 8.4,
      );

      expect(
        formatSlot(slot),
        'Wednesday 15 Apr, 07:00–08:00 — 14°C, 10% rain, '
        '8 km/h wind — Score: 0.87',
      );
    });
  });

  group('[Unit] Phase1SmokeTestRunner', () {
    test(
      'should print recommendations and status summary when fetch succeeds',
      () async {
        final output = <String>[];
        final errors = <String>[];
        final scheduler = _FakeRunScheduler({
          3: <TimeSlot>[
            _slot(startTime: DateTime(2026, 3, 17, 7), score: 0.91),
          ],
          5: <TimeSlot>[
            _slot(startTime: DateTime(2026, 3, 18, 7), score: 0.83),
            _slot(startTime: DateTime(2026, 3, 19, 7), score: 0.81),
          ],
          7: <TimeSlot>[
            _slot(startTime: DateTime(2026, 3, 20, 7), score: 0.79),
            _slot(startTime: DateTime(2026, 3, 21, 7), score: 0.78),
            _slot(startTime: DateTime(2026, 3, 22, 7), score: 0.77),
          ],
        });
        var requestedLat = 0.0;
        var requestedLng = 0.0;
        final runner = Phase1SmokeTestRunner(
          fetchForecast: (lat, lng) async {
            requestedLat = lat;
            requestedLng = lng;
            return _weatherResult();
          },
          hadFreshCache: false,
          scheduler: scheduler,
          output: output.add,
          errorOutput: errors.add,
        );

        final exitCode = await runner.run();

        expect(exitCode, 0);
        expect(errors, isEmpty);
        expect(requestedLat, Phase1SmokeTestRunner.northamptonLat);
        expect(requestedLng, Phase1SmokeTestRunner.northamptonLng);
        expect(scheduler.calls, hasLength(3));
        expect(scheduler.calls[0].numberOfRuns, 3);
        expect(scheduler.calls[0].preferredPeriods, <String>[
          'morning',
          'afternoon',
          'evening',
        ]);
        expect(scheduler.calls[1].numberOfRuns, 5);
        expect(scheduler.calls[1].preferredPeriods, <String>['morning']);
        expect(scheduler.calls[2].numberOfRuns, 7);
        expect(scheduler.calls[2].preferredPeriods, <String>[
          'morning',
          'afternoon',
          'evening',
        ]);
        expect(scheduler.calls[0].forecasts, hasLength(2));
        expect(scheduler.calls[0].sunData, hasLength(1));
        expect(output, contains('=== Phase 1 Integration Smoke Test ==='));
        expect(
          output,
          contains('Location: Northampton, UK (52.2405, -0.9027)'),
        );
        expect(output, contains('Weather data: 2 hourly points'));
        expect(output, contains('Source: live API'));
        expect(
          output,
          contains(
            'Slot 1: Tuesday 17 Mar, 07:00–08:00 — 14°C, '
            '10% rain, 8 km/h wind — Score: 0.91',
          ),
        );
        expect(output, contains('=== Best Slots: 5 Runs, Morning Only ==='));
        expect(output, contains('=== Phase 1 Status ==='));
        expect(output, contains('✓ Algorithm: returned 1 slots for 3 runs'));
        expect(
          output,
          contains('✓ Morning-only filter: returned 2 slots for 5 runs'),
        );
        expect(output, contains('✓ Full week: returned 3 slots for 7 runs'));
      },
    );

    test(
      'should print empty-state messaging when scheduler returns no slots',
      () async {
        final output = <String>[];
        final runner = Phase1SmokeTestRunner(
          fetchForecast: (lat, lng) async => _weatherResult(isStale: true),
          hadFreshCache: true,
          scheduler: _FakeRunScheduler(const {}),
          output: output.add,
          errorOutput: (_) {},
        );

        final exitCode = await runner.run();

        expect(exitCode, 0);
        expect(
          output.where((line) => line == 'No matching slots found.'),
          hasLength(3),
        );
        expect(output, contains('Source: cache (stale fallback)'));
        expect(output, contains('✓ Algorithm: returned 0 slots for 3 runs'));
        expect(
          output,
          contains('✓ Morning-only filter: returned 0 slots for 5 runs'),
        );
        expect(output, contains('✓ Full week: returned 0 slots for 7 runs'));
      },
    );

    test(
      'should print a friendly error and return failure when fetch fails',
      () async {
        final output = <String>[];
        final errors = <String>[];
        final runner = Phase1SmokeTestRunner(
          fetchForecast: (lat, lng) async => throw Exception('No internet'),
          hadFreshCache: false,
          output: output.add,
          errorOutput: errors.add,
        );

        final exitCode = await runner.run();

        expect(exitCode, 1);
        expect(output, isEmpty);
        expect(errors, hasLength(3));
        expect(errors[0], 'Phase 1 smoke test failed.');
        expect(
          errors[1],
          'Unable to fetch weather data or run the scheduler. '
          'Check your internet connection and try again.',
        );
        expect(errors[2], contains('No internet'));
      },
    );
  });
}
