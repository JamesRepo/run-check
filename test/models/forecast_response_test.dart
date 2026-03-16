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
        sunrises: const [],
        sunsets: const [],
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
        'daily': {
          'sunrise': <String>[],
          'sunset': <String>[],
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

    test('should parse sunrise and sunset from daily json when present', () {
      final response = ForecastResponse.fromJson({
        'latitude': 51.5,
        'longitude': -0.13,
        'timezone': 'Europe/London',
        'hourly': {
          'time': ['2026-03-16T09:00'],
          'temperature_2m': [12.4],
          'precipitation_probability': [30],
          'windspeed_10m': [16.5],
          'relativehumidity_2m': [65],
          'weathercode': [3],
        },
        'daily': {
          'sunrise': ['2026-03-16T06:15', '2026-03-17T06:13'],
          'sunset': ['2026-03-16T18:10', '2026-03-17T18:12'],
        },
      });

      expect(response.sunrises, hasLength(2));
      expect(response.sunrises.first, DateTime.parse('2026-03-16T06:15'));
      expect(response.sunrises.last, DateTime.parse('2026-03-17T06:13'));
      expect(response.sunsets, hasLength(2));
      expect(response.sunsets.first, DateTime.parse('2026-03-16T18:10'));
      expect(response.sunsets.last, DateTime.parse('2026-03-17T18:12'));
    });

    test(
      'should default sunrises and sunsets to empty lists '
      'when daily key is missing',
      () {
        final response = ForecastResponse.fromJson({
          'latitude': 51.5,
          'longitude': -0.13,
          'timezone': 'Europe/London',
          'hourly': {
            'time': ['2026-03-16T09:00'],
            'temperature_2m': [12.4],
            'precipitation_probability': [30],
            'windspeed_10m': [16.5],
            'relativehumidity_2m': [65],
            'weathercode': [3],
          },
        });

        expect(response.sunrises, isEmpty);
        expect(response.sunsets, isEmpty);
      },
    );

    test('should default isStale to false when parsed from json', () {
      final response = ForecastResponse.fromJson({
        'latitude': 51.5,
        'longitude': -0.13,
        'timezone': 'Europe/London',
        'hourly': {
          'time': ['2026-03-16T09:00'],
          'temperature_2m': [12.4],
          'precipitation_probability': [30],
          'windspeed_10m': [16.5],
          'relativehumidity_2m': [65],
          'weathercode': [3],
        },
      });

      expect(response.isStale, isFalse);
    });

    test('should set isStale to true when fromJson is called with isStale', () {
      final response = ForecastResponse.fromJson(
        {
          'latitude': 51.5,
          'longitude': -0.13,
          'timezone': 'Europe/London',
          'hourly': {
            'time': ['2026-03-16T09:00'],
            'temperature_2m': [12.4],
            'precipitation_probability': [30],
            'windspeed_10m': [16.5],
            'relativehumidity_2m': [65],
            'weathercode': [3],
          },
        },
        isStale: true,
      );

      expect(response.isStale, isTrue);
    });

    test(
      'should change only isStale when copyWith is called with isStale',
      () {
        final original = ForecastResponse(
          latitude: 51.5,
          longitude: -0.13,
          timezone: 'Europe/London',
          sunrises: [DateTime.parse('2026-03-16T06:15')],
          sunsets: [DateTime.parse('2026-03-16T18:10')],
          hourlyForecasts: const [],
        );

        final copy = original.copyWith(isStale: true);

        expect(copy.isStale, isTrue);
        expect(copy.latitude, original.latitude);
        expect(copy.longitude, original.longitude);
        expect(copy.timezone, original.timezone);
        expect(copy.sunrises, original.sunrises);
        expect(copy.sunsets, original.sunsets);
        expect(copy.hourlyForecasts, original.hourlyForecasts);
      },
    );

    test(
      'should keep original isStale when copyWith is called without arguments',
      () {
        const original = ForecastResponse(
          latitude: 51.5,
          longitude: -0.13,
          timezone: 'Europe/London',
          sunrises: [],
          sunsets: [],
          hourlyForecasts: [],
          isStale: true,
        );

        final copy = original.copyWith();

        expect(copy.isStale, isTrue);
      },
    );

    test(
      'should serialize sunrise and sunset into daily json '
      'when toJson is called with daily data',
      () {
        final response = ForecastResponse(
          latitude: 51.5,
          longitude: -0.13,
          timezone: 'Europe/London',
          sunrises: [DateTime.parse('2026-03-16T06:15:00.000')],
          sunsets: [DateTime.parse('2026-03-16T18:10:00.000')],
          hourlyForecasts: const [],
        );

        final json = response.toJson();
        final daily = json['daily'] as Map<String, dynamic>;

        expect(daily['sunrise'], ['2026-03-16T06:15:00.000']);
        expect(daily['sunset'], ['2026-03-16T18:10:00.000']);
      },
    );

    test(
      'should survive a round trip through toJson and fromJson '
      'for daily data',
      () {
        final original = ForecastResponse(
          latitude: 51.5,
          longitude: -0.13,
          timezone: 'Europe/London',
          sunrises: [
            DateTime.parse('2026-03-16T06:15:00.000'),
            DateTime.parse('2026-03-17T06:13:00.000'),
          ],
          sunsets: [
            DateTime.parse('2026-03-16T18:10:00.000'),
            DateTime.parse('2026-03-17T18:12:00.000'),
          ],
          hourlyForecasts: [
            HourlyForecast(
              dateTime: DateTime.parse('2026-03-16T09:00:00.000'),
              temperature: 12.4,
              precipitationProbability: 30,
              windSpeed: 16.5,
              humidity: 65,
              weatherCode: 3,
            ),
          ],
        );

        final roundTripped = ForecastResponse.fromJson(original.toJson());

        expect(roundTripped.latitude, original.latitude);
        expect(roundTripped.longitude, original.longitude);
        expect(roundTripped.timezone, original.timezone);
        expect(roundTripped.sunrises, original.sunrises);
        expect(roundTripped.sunsets, original.sunsets);
        expect(roundTripped.hourlyForecasts, hasLength(1));
        expect(
          roundTripped.hourlyForecasts.first.temperature,
          original.hourlyForecasts.first.temperature,
        );
      },
    );
  });
}
