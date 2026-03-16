import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/services/weather_service.dart';

void main() {
  group('[Unit] WeatherProvider', () {
    test('should update forecast state when fetching succeeds', () async {
      final forecast = buildForecastResponse();
      final fakeService = FakeWeatherService(
        weatherResult: WeatherResult(forecast: forecast, isStale: true),
      );
      final container = ProviderContainer(
        overrides: [weatherServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container
          .read(weatherProvider.notifier)
          .fetchForecast(testLocation);

      final state = container.read(weatherProvider);
      expect(state.forecast, same(forecast));
      expect(state.isStale, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(fakeService.lastCoordinates, (51.5072, -0.1276));
    });

    test('should expose an error when fetching fails', () async {
      final fakeService = FakeWeatherService(error: Exception('Network down'));
      final container = ProviderContainer(
        overrides: [weatherServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container
          .read(weatherProvider.notifier)
          .fetchForecast(testLocation);

      final state = container.read(weatherProvider);
      expect(state.forecast, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Network down');
    });

    test(
      'should keep the previous forecast when a later fetch fails',
      () async {
        final forecast = buildForecastResponse();
        final fakeService = FakeWeatherService(
          weatherResult: WeatherResult(forecast: forecast, isStale: false),
        );
        final container = ProviderContainer(
          overrides: [weatherServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        await container
            .read(weatherProvider.notifier)
            .fetchForecast(testLocation);
        fakeService.error = Exception('Timeout');
        await container
            .read(weatherProvider.notifier)
            .fetchForecast(testLocation);

        final state = container.read(weatherProvider);
        expect(state.forecast, same(forecast));
        expect(state.errorMessage, 'Timeout');
      },
    );
  });

  group('[Widget] WeatherProvider', () {
    testWidgets('should rebuild the widget when forecast loading completes', (
      tester,
    ) async {
      final fakeService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [weatherServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: _WeatherConsumerWidget()),
        ),
      );

      expect(find.text('empty'), findsOneWidget);

      await tester.tap(find.text('Fetch'));
      await tester.pumpAndSettle();

      expect(find.text('loaded'), findsOneWidget);
    });
  });
}

class FakeWeatherService extends WeatherService {
  FakeWeatherService({this.weatherResult, this.error}) : super();

  WeatherResult? weatherResult;
  Exception? error;
  (double, double)? lastCoordinates;

  @override
  Future<WeatherResult> fetchHourlyForecast(double lat, double lng) async {
    lastCoordinates = (lat, lng);
    if (error != null) {
      throw error!;
    }

    return weatherResult!;
  }
}

class _WeatherConsumerWidget extends ConsumerWidget {
  const _WeatherConsumerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider);

    return Scaffold(
      body: Column(
        children: [
          Text(state.forecast == null ? 'empty' : 'loaded'),
          ElevatedButton(
            onPressed: () {
              ref.read(weatherProvider.notifier).fetchForecast(testLocation);
            },
            child: const Text('Fetch'),
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
