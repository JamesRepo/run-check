import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/weather_result.dart';

Map<String, dynamic> _forecastJson() {
  return {
    'latitude': 51.5,
    'longitude': -0.13,
    'timezone': 'Europe/London',
    'hourly': {
      'time': ['2026-03-16T09:00', '2026-03-16T10:00'],
      'temperature_2m': [12.4, 13.8],
      'precipitation_probability': [30, 15],
      'windspeed_10m': [16.5, 12.1],
      'relativehumidity_2m': [65.0, 62.0],
      'weathercode': [3, 2],
    },
    'daily': {
      'time': ['2026-03-16', '2026-03-17'],
      'sunrise': ['2026-03-16T06:15', '2026-03-17T06:13'],
      'sunset': ['2026-03-16T18:10', '2026-03-17T18:12'],
    },
  };
}

void main() {
  group('[Unit] WeatherResult', () {
    test('should expose the stale flag when created with stale data', () {
      final result = WeatherResult(
        forecast: ForecastResponse.fromJson(_forecastJson()),
        isStale: true,
      );

      expect(result.isStale, isTrue);
    });

    test(
      'should proxy forecast metadata when accessing convenience getters',
      () {
        final result = WeatherResult(
          forecast: ForecastResponse.fromJson(_forecastJson()),
          isStale: false,
        );

        expect(result.latitude, 51.5);
        expect(result.longitude, -0.13);
        expect(result.timezone, 'Europe/London');
      },
    );

    test(
      'should proxy hourly and daily forecast collections when requested',
      () {
        final result = WeatherResult(
          forecast: ForecastResponse.fromJson(_forecastJson()),
          isStale: false,
        );

        expect(result.hourlyForecasts, hasLength(2));
        expect(result.dailySunData, hasLength(2));
        expect(result.sunrises.first, DateTime.parse('2026-03-16T06:15'));
        expect(result.sunsets.last, DateTime.parse('2026-03-17T18:12'));
      },
    );
  });
}
