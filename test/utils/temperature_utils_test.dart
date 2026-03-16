import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/temperature_utils.dart';

void main() {
  group('[Unit] celsiusToFahrenheit', () {
    test('should return 32 when given 0°C (freezing point)', () {
      expect(celsiusToFahrenheit(0), 32.0);
    });

    test('should return 212 when given 100°C (boiling point)', () {
      expect(celsiusToFahrenheit(100), 212.0);
    });

    test('should return -40 when given -40°C (convergence point)', () {
      expect(celsiusToFahrenheit(-40), -40.0);
    });

    test('should return 98.6 when given 37°C (body temperature)', () {
      expect(celsiusToFahrenheit(37), closeTo(98.6, 0.01));
    });

    test('should handle fractional Celsius values', () {
      expect(celsiusToFahrenheit(14.5), closeTo(58.1, 0.01));
    });

    test('should handle negative Celsius values', () {
      expect(celsiusToFahrenheit(-10), closeTo(14.0, 0.01));
    });
  });
}
