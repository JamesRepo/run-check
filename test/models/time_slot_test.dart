import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/time_slot.dart';

void main() {
  group('[Unit] TimeSlot', () {
    test('should parse a scored time slot when json values are valid', () {
      final timeSlot = TimeSlot.fromJson({
        'start_time': '2026-03-16T09:00',
        'end_time': '2026-03-16T10:00',
        'score': 0.82,
        'temperature': 12.4,
        'precipitation_probability': 20,
        'wind_speed': 11.5,
        'weather_code': 61,
        'weather_description': 'Slight rain',
      });

      expect(timeSlot.startTime, DateTime.parse('2026-03-16T09:00'));
      expect(timeSlot.endTime, DateTime.parse('2026-03-16T10:00'));
      expect(timeSlot.score, 0.82);
      expect(timeSlot.temperature, 12.4);
      expect(timeSlot.precipitationProbability, 20);
      expect(timeSlot.windSpeed, 11.5);
      expect(timeSlot.weatherCode, 61);
      expect(timeSlot.weatherDescription, 'Slight rain');
    });

    test(
      'should coerce numeric values to doubles and ints '
      'when json uses num types',
        () {
      final timeSlot = TimeSlot.fromJson({
        'start_time': '2026-03-16T09:00',
        'end_time': '2026-03-16T10:00',
        'score': 1,
        'temperature': 13,
        'precipitation_probability': 40.9,
        'wind_speed': 8,
        'weather_code': 3.7,
        'weather_description': 'Overcast',
      });

      expect(timeSlot.score, 1);
      expect(timeSlot.temperature, 13);
      expect(timeSlot.precipitationProbability, 40);
      expect(timeSlot.windSpeed, 8);
      expect(timeSlot.weatherCode, 3);
    });

    test('should serialize to the expected json shape when built', () {
      final timeSlot = TimeSlot(
        startTime: DateTime.parse('2026-03-16T09:00:00.000'),
        endTime: DateTime.parse('2026-03-16T10:00:00.000'),
        score: 0.75,
        temperature: 12.5,
        precipitationProbability: 15,
        windSpeed: 10.2,
        weatherCode: 2,
        weatherDescription: 'Partly cloudy',
      );

      expect(timeSlot.toJson(), {
        'start_time': '2026-03-16T09:00:00.000',
        'end_time': '2026-03-16T10:00:00.000',
        'score': 0.75,
        'temperature': 12.5,
        'precipitation_probability': 15,
        'wind_speed': 10.2,
        'weather_code': 2,
        'weather_description': 'Partly cloudy',
      });
    });

    test('should throw a FormatException when a numeric field is not numeric',
        () {
      expect(
        () => TimeSlot.fromJson({
          'start_time': '2026-03-16T09:00',
          'end_time': '2026-03-16T10:00',
          'score': 'high',
          'temperature': 12.4,
          'precipitation_probability': 20,
          'wind_speed': 11.5,
          'weather_code': 61,
          'weather_description': 'Slight rain',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'should throw a FormatException when start time '
      'is not a valid ISO date',
        () {
      expect(
        () => TimeSlot.fromJson({
          'start_time': 'not-a-date',
          'end_time': '2026-03-16T10:00',
          'score': 0.82,
          'temperature': 12.4,
          'precipitation_probability': 20,
          'wind_speed': 11.5,
          'weather_code': 61,
          'weather_description': 'Slight rain',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
