import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/location_data.dart';

void main() {
  group('[Unit] LocationData', () {
    test('should parse values from json when numeric fields are valid', () {
      final location = LocationData.fromJson({
        'latitude': 52.2405,
        'longitude': -0.9027,
        'displayName': 'Northampton, UK',
      });

      expect(location.latitude, 52.2405);
      expect(location.longitude, -0.9027);
      expect(location.displayName, 'Northampton, UK');
    });

    test('should serialize values to json when requested', () {
      const location = LocationData(
        latitude: 52.2405,
        longitude: -0.9027,
        displayName: 'Northampton, UK',
      );

      expect(location.toJson(), {
        'latitude': 52.2405,
        'longitude': -0.9027,
        'displayName': 'Northampton, UK',
      });
    });

    test('should throw FormatException when latitude is not numeric', () {
      expect(
        () => LocationData.fromJson({
          'latitude': 'north',
          'longitude': -0.9027,
          'displayName': 'Northampton, UK',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
