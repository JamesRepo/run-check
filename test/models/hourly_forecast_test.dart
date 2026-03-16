import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/hourly_forecast.dart';

void main() {
  group('[Unit] HourlyForecast', () {
    test('should parse a single hourly entry when json values are valid', () {
      final forecast = HourlyForecast.fromJson({
        'time': '2026-03-16T09:00',
        'temperature_2m': 12.5,
        'precipitation_probability': 30,
        'windspeed_10m': 18.2,
        'relativehumidity_2m': 66.0,
        'weathercode': 3,
      });

      expect(forecast.dateTime, DateTime.parse('2026-03-16T09:00'));
      expect(forecast.temperature, 12.5);
      expect(forecast.precipitationProbability, 30);
      expect(forecast.windSpeed, 18.2);
      expect(forecast.humidity, 66);
      expect(forecast.weatherCode, 3);
    });

    test('should coerce numeric values to doubles and ints '
        'when json uses num types', () {
      final forecast = HourlyForecast.fromJson({
        'time': '2026-03-16T10:00',
        'temperature_2m': 14,
        'precipitation_probability': 45.9,
        'windspeed_10m': 20,
        'relativehumidity_2m': 70,
        'weathercode': 61.4,
      });

      expect(forecast.temperature, 14);
      expect(forecast.precipitationProbability, 45);
      expect(forecast.windSpeed, 20);
      expect(forecast.humidity, 70);
      expect(forecast.weatherCode, 61);
    });

    test(
      'should serialize to the expected Open-Meteo field names when built',
      () {
        final forecast = HourlyForecast(
          dateTime: DateTime.parse('2026-03-16T11:00:00.000'),
          temperature: 15.3,
          precipitationProbability: 10,
          windSpeed: 9.8,
          humidity: 58,
          weatherCode: 1,
        );

        expect(forecast.toJson(), {
          'time': '2026-03-16T11:00:00.000',
          'temperature_2m': 15.3,
          'precipitation_probability': 10,
          'windspeed_10m': 9.8,
          'relativehumidity_2m': 58,
          'weathercode': 1,
        });
      },
    );

    test(
      'should throw a FormatException when a numeric field is not numeric',
      () {
        expect(
          () => HourlyForecast.fromJson({
            'time': '2026-03-16T12:00',
            'temperature_2m': 'warm',
            'precipitation_probability': 20,
            'windspeed_10m': 8.5,
            'relativehumidity_2m': 60,
            'weathercode': 0,
          }),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('should default numeric fields to zero when api values are null', () {
      final forecast = HourlyForecast.fromJson({
        'time': '2026-03-16T13:00',
        'temperature_2m': null,
        'precipitation_probability': null,
        'windspeed_10m': null,
        'relativehumidity_2m': null,
        'weathercode': null,
      });

      expect(forecast.temperature, 0);
      expect(forecast.precipitationProbability, 0);
      expect(forecast.windSpeed, 0);
      expect(forecast.humidity, 0);
      expect(forecast.weatherCode, 0);
    });

    test(
      'should throw a FormatException when time is not a valid ISO date',
      () {
        expect(
          () => HourlyForecast.fromJson({
            'time': 'not-a-date',
            'temperature_2m': 11,
            'precipitation_probability': 20,
            'windspeed_10m': 8.5,
            'relativehumidity_2m': 60,
            'weathercode': 0,
          }),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
