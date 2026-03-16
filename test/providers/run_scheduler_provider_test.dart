import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/services/run_scheduler.dart';
import 'package:run_check/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Unit] RunSchedulerProvider', () {
    test('should expose an error when no forecast has been loaded', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(runSchedulerProvider.notifier)
          .findSlots(numberOfRuns: 3);

      final state = container.read(runSchedulerProvider);
      expect(state.slots, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.requestedRuns, 3);
      expect(state.errorMessage, 'No forecast available for scheduling.');
    });

    test('should pass forecast data and settings into the scheduler '
        'when finding slots', () async {
      final fakeWeatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );
      final fakeScheduler = FakeRunScheduler(
        slotsToReturn: [
          TimeSlot(
            startTime: DateTime.utc(2026, 3, 16, 9),
            endTime: DateTime.utc(2026, 3, 16, 10),
            score: 0.88,
            temperature: 14,
            precipitationProbability: 10,
            windSpeed: 8,
            weatherCode: 1,
            weatherDescription: 'Mainly clear',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          weatherServiceProvider.overrideWithValue(fakeWeatherService),
          runSchedulerServiceProvider.overrideWithValue(fakeScheduler),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setPreferredPeriods([
        'evening',
      ]);
      await container.read(settingsProvider.notifier).setRunDuration(45);
      await container
          .read(weatherProvider.notifier)
          .fetchForecast(testLocation);

      await container
          .read(runSchedulerProvider.notifier)
          .findSlots(numberOfRuns: 2);

      final state = container.read(runSchedulerProvider);
      expect(state.slots, hasLength(1));
      expect(state.requestedRuns, 2);
      expect(fakeScheduler.lastNumberOfRuns, 2);
      expect(fakeScheduler.lastRunDurationMinutes, 45);
      expect(fakeScheduler.lastPreferredPeriods, ['evening']);
      expect(fakeScheduler.lastForecasts, hasLength(2));
      expect(fakeScheduler.lastSunData, hasLength(1));
    });

    test('should expose an error when the scheduler throws', () async {
      final fakeWeatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );
      final fakeScheduler = FakeRunScheduler(
        error: Exception('Scheduling failed'),
      );
      final container = ProviderContainer(
        overrides: [
          weatherServiceProvider.overrideWithValue(fakeWeatherService),
          runSchedulerServiceProvider.overrideWithValue(fakeScheduler),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(weatherProvider.notifier)
          .fetchForecast(testLocation);
      await container
          .read(runSchedulerProvider.notifier)
          .findSlots(numberOfRuns: 1);

      final state = container.read(runSchedulerProvider);
      expect(state.slots, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Scheduling failed');
    });
  });

  group('[Widget] RunSchedulerProvider', () {
    testWidgets('should rebuild the widget when scheduling succeeds', (
      tester,
    ) async {
      final fakeWeatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );
      final fakeScheduler = FakeRunScheduler(
        slotsToReturn: [
          TimeSlot(
            startTime: DateTime.utc(2026, 3, 16, 9),
            endTime: DateTime.utc(2026, 3, 16, 10),
            score: 0.88,
            temperature: 14,
            precipitationProbability: 10,
            windSpeed: 8,
            weatherCode: 1,
            weatherDescription: 'Mainly clear',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherServiceProvider.overrideWithValue(fakeWeatherService),
            runSchedulerServiceProvider.overrideWithValue(fakeScheduler),
          ],
          child: const MaterialApp(home: _RunSchedulerConsumerWidget()),
        ),
      );

      await tester.tap(find.text('Prepare'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });
  });
}

class FakeWeatherService extends WeatherService {
  FakeWeatherService({required this.weatherResult}) : super();

  final WeatherResult weatherResult;

  @override
  Future<WeatherResult> fetchHourlyForecast(double lat, double lng) async {
    return weatherResult;
  }
}

class FakeRunScheduler extends RunScheduler {
  FakeRunScheduler({this.slotsToReturn = const [], this.error});

  final List<TimeSlot> slotsToReturn;
  final Exception? error;

  List<HourlyForecast>? lastForecasts;
  int? lastNumberOfRuns;
  int? lastRunDurationMinutes;
  List<String>? lastPreferredPeriods;
  List<SunriseSunset>? lastSunData;

  @override
  List<TimeSlot> findBestSlots({
    required List<HourlyForecast> forecasts,
    required int numberOfRuns,
    int runDurationMinutes = 60,
    List<String> preferredPeriods = const ['morning', 'afternoon', 'evening'],
    List<SunriseSunset>? sunData,
  }) {
    lastForecasts = forecasts;
    lastNumberOfRuns = numberOfRuns;
    lastRunDurationMinutes = runDurationMinutes;
    lastPreferredPeriods = preferredPeriods;
    lastSunData = sunData;

    if (error != null) {
      throw error!;
    }

    return slotsToReturn;
  }
}

class _RunSchedulerConsumerWidget extends ConsumerWidget {
  const _RunSchedulerConsumerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(runSchedulerProvider);

    return Scaffold(
      body: Column(
        children: [
          Text('${scheduleState.slots.length}'),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(weatherProvider.notifier)
                  .fetchForecast(testLocation);
            },
            child: const Text('Prepare'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(runSchedulerProvider.notifier)
                  .findSlots(numberOfRuns: 1);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

const testLocation = LocationData(
  latitude: 51.5072,
  longitude: -0.1276,
  displayName: 'London, UK',
);

ForecastResponse buildForecastResponse() {
  return ForecastResponse(
    latitude: 51.5072,
    longitude: -0.1276,
    timezone: 'Europe/London',
    hourlyForecasts: [
      HourlyForecast(
        dateTime: DateTime.utc(2026, 3, 16, 9),
        temperature: 14,
        precipitationProbability: 15,
        windSpeed: 8,
        humidity: 55,
        weatherCode: 1,
      ),
      HourlyForecast(
        dateTime: DateTime.utc(2026, 3, 16, 10),
        temperature: 15,
        precipitationProbability: 10,
        windSpeed: 7,
        humidity: 50,
        weatherCode: 1,
      ),
    ],
    dailySunData: [
      SunriseSunset(
        date: DateTime.utc(2026, 3, 16),
        sunrise: DateTime.utc(2026, 3, 16, 6, 20),
        sunset: DateTime.utc(2026, 3, 16, 18, 10),
      ),
    ],
  );
}
