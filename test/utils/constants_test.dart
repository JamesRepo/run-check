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
  });
}
