import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/sunrise_sunset.dart';

void main() {
  group('[Unit] SunriseSunset', () {
    test('should parse a daily sun entry when json values are valid', () {
      final sunData = SunriseSunset.fromJson({
        'time': '2026-03-16',
        'sunrise': '2026-03-16T06:15',
        'sunset': '2026-03-16T18:10',
      });

      expect(sunData.date, DateTime.parse('2026-03-16'));
      expect(sunData.sunrise, DateTime.parse('2026-03-16T06:15'));
      expect(sunData.sunset, DateTime.parse('2026-03-16T18:10'));
    });

    test('should serialize back to the expected json shape when built', () {
      final sunData = SunriseSunset(
        date: DateTime.parse('2026-03-16'),
        sunrise: DateTime.parse('2026-03-16T06:15:00.000'),
        sunset: DateTime.parse('2026-03-16T18:10:00.000'),
      );

      expect(sunData.toJson(), {
        'time': '2026-03-16T00:00:00.000',
        'sunrise': '2026-03-16T06:15:00.000',
        'sunset': '2026-03-16T18:10:00.000',
      });
    });

    test('should throw a FormatException when the date is invalid', () {
      expect(
        () => SunriseSunset.fromJson({
          'time': 'not-a-date',
          'sunrise': '2026-03-16T06:15',
          'sunset': '2026-03-16T18:10',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
