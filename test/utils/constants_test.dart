import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/constants.dart';

void main() {
  group('[Unit] weather constants', () {
    test(
      'should expose the expected Open-Meteo forecast URL when requested',
      () {
        expect(openMeteoBaseUrl, 'https://api.open-meteo.com/v1/forecast');
      },
    );

    test('should expose a valid absolute https URL when parsed', () {
      final uri = Uri.parse(openMeteoBaseUrl);

      expect(uri.isAbsolute, isTrue);
      expect(uri.scheme, 'https');
      expect(uri.host, 'api.open-meteo.com');
      expect(uri.path, '/v1/forecast');
    });

    test('should keep every scoring weight between zero and one when read', () {
      expect(precipitationWeight, inInclusiveRange(0.0, 1.0));
      expect(temperatureWeight, inInclusiveRange(0.0, 1.0));
      expect(windWeight, inInclusiveRange(0.0, 1.0));
      expect(humidityWeight, inInclusiveRange(0.0, 1.0));
    });

    test(
      'should total one point zero when all scoring weights are combined',
      () {
        const totalWeight =
            precipitationWeight +
            temperatureWeight +
            windWeight +
            humidityWeight;

        expect(totalWeight, closeTo(1.0, 0.000001));
      },
    );

    test('should expose weather descriptions for common wmo weather codes',
        () {
      expect(weatherCodeDescriptions[0], 'Clear sky');
      expect(weatherCodeDescriptions[2], 'Partly cloudy');
      expect(weatherCodeDescriptions[61], 'Slight rain');
      expect(weatherCodeDescriptions[95], 'Thunderstorm');
    });

    test('should include descriptions for every required weather code', () {
      expect(
        weatherCodeDescriptions.keys,
        containsAll([
          0,
          1,
          2,
          3,
          45,
          48,
          51,
          53,
          55,
          61,
          63,
          65,
          71,
          73,
          75,
          80,
          81,
          82,
          95,
          96,
          99,
        ]),
      );
    });
  });
}
