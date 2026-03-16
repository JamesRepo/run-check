import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';

void main() {
  group('[Unit] ForecastResponse', () {
    test(
      'should parse top level metadata and hourly forecasts when json is valid',
      () {
        final response = ForecastResponse.fromJson({
          'latitude': 51.5072,
          'longitude': -0.1276,
          'timezone': 'Europe/London',
          'hourly': {
            'time': ['2026-03-16T09:00', '2026-03-16T10:00'],
            'temperature_2m': [12.4, 13.8],
            'precipitation_probability': [30, 15],
            'windspeed_10m': [16.5, 12.1],
            'relativehumidity_2m': [65, 62],
            'weathercode': [3, 2],
          },
        });

        expect(response.latitude, 51.5072);
        expect(response.longitude, -0.1276);
        expect(response.timezone, 'Europe/London');
        expect(response.hourlyForecasts, hasLength(2));
        expect(response.hourlyForecasts.first.toJson(), {
          'time': '2026-03-16T09:00:00.000',
          'temperature_2m': 12.4,
          'precipitation_probability': 30,
          'windspeed_10m': 16.5,
          'relativehumidity_2m': 65,
          'weathercode': 3,
        });
      },
    );

    test('should zip hourly arrays using the shortest length '
        'when arrays are mismatched', () {
      final response = ForecastResponse.fromJson({
        'latitude': 51.5,
        'longitude': -0.12,
        'timezone': 'Europe/London',
        'hourly': {
          'time': ['2026-03-16T09:00', '2026-03-16T10:00', '2026-03-16T11:00'],
          'temperature_2m': [12.4, 13.8],
          'precipitation_probability': [30, 15, 5],
          'windspeed_10m': [16.5, 12.1, 11.9],
          'relativehumidity_2m': [65, 62, 60],
          'weathercode': [3, 2, 1],
        },
      });

      expect(response.hourlyForecasts, hasLength(2));
      expect(
        response.hourlyForecasts.map((forecast) => forecast.dateTime).toList(),
        [
          DateTime.parse('2026-03-16T09:00'),
          DateTime.parse('2026-03-16T10:00'),
        ],
      );
    });

    test(
      'should return an empty hourly list when all hourly arrays are empty',
      () {
        final response = ForecastResponse.fromJson({
          'latitude': 51.5,
          'longitude': -0.12,
          'timezone': 'Europe/London',
          'hourly': {
            'time': <String>[],
            'temperature_2m': <double>[],
            'precipitation_probability': <int>[],
            'windspeed_10m': <double>[],
            'relativehumidity_2m': <int>[],
            'weathercode': <int>[],
          },
        });

        expect(response.hourlyForecasts, isEmpty);
      },
    );

    test('should serialize hourly forecasts back into parallel arrays '
        'when requested', () {
      final response = ForecastResponse(
        latitude: 51.5072,
        longitude: -0.1276,
        timezone: 'Europe/London',
        hourlyForecasts: [
          HourlyForecast(
            dateTime: DateTime.parse('2026-03-16T09:00:00.000'),
            temperature: 12.4,
            precipitationProbability: 30,
            windSpeed: 16.5,
            humidity: 65,
            weatherCode: 3,
          ),
          HourlyForecast(
            dateTime: DateTime.parse('2026-03-16T10:00:00.000'),
            temperature: 13.8,
            precipitationProbability: 15,
            windSpeed: 12.1,
            humidity: 62,
            weatherCode: 2,
          ),
        ],
      );

      expect(response.toJson(), {
        'latitude': 51.5072,
        'longitude': -0.1276,
        'timezone': 'Europe/London',
        'hourly': {
          'time': ['2026-03-16T09:00:00.000', '2026-03-16T10:00:00.000'],
          'temperature_2m': [12.4, 13.8],
          'precipitation_probability': [30, 15],
          'windspeed_10m': [16.5, 12.1],
          'relativehumidity_2m': [65, 62],
          'weathercode': [3, 2],
        },
      });
    });

    test('should throw a FormatException '
        'when top level coordinates are not numeric', () {
      expect(
        () => ForecastResponse.fromJson({
          'latitude': 'north',
          'longitude': -0.1276,
          'timezone': 'Europe/London',
          'hourly': {
            'time': ['2026-03-16T09:00'],
            'temperature_2m': [12.4],
            'precipitation_probability': [30],
            'windspeed_10m': [16.5],
            'relativehumidity_2m': [65],
            'weathercode': [3],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw a FormatException '
        'when a nested hourly numeric value is invalid', () {
      expect(
        () => ForecastResponse.fromJson({
          'latitude': 51.5072,
          'longitude': -0.1276,
          'timezone': 'Europe/London',
          'hourly': {
            'time': ['2026-03-16T09:00'],
            'temperature_2m': ['cold'],
            'precipitation_probability': [30],
            'windspeed_10m': [16.5],
            'relativehumidity_2m': [65],
            'weathercode': [3],
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
