import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:run_check/services/weather_cache_service.dart';
import 'package:run_check/services/weather_service.dart';

Map<String, dynamic> _validApiJson({
  double latitude = 51.5,
  double longitude = -0.13,
}) {
  return {
    'latitude': latitude,
    'longitude': longitude,
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

String _validApiBody({double latitude = 51.5, double longitude = -0.13}) =>
    jsonEncode(_validApiJson(latitude: latitude, longitude: longitude));

Future<void> _seedCache(
  Box<dynamic> box, {
  double lat = 51.5,
  double lng = -0.13,
  Duration age = Duration.zero,
  String? rawForecast,
}) async {
  await box.put(
    'forecast',
    rawForecast ?? _validApiBody(latitude: lat, longitude: lng),
  );
  await box.put(
    'forecast_timestamp',
    DateTime.now().toUtc().subtract(age).millisecondsSinceEpoch,
  );
  await box.put('forecast_lat', lat);
  await box.put('forecast_lng', lng);
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('weather_service_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    try {
      await Hive.deleteBoxFromDisk(WeatherCacheService.boxName);
    } on Exception {
      // Box file might not exist if the test never opened it.
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('[Unit] WeatherFetchException', () {
    test('should store the provided message when created', () {
      const exception = WeatherFetchException('something went wrong');

      expect(exception.message, 'something went wrong');
    });

    test('should include the message in toString when converted to string', () {
      const exception = WeatherFetchException('timeout');

      expect(exception.toString(), 'WeatherFetchException: timeout');
    });
  });

  group('[Unit] WeatherService', () {
    test('should send a GET request with the expected forecast query '
        'when fetching', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(_validApiBody(), 200);
      });

      final service = WeatherService(httpClient: client, hive: Hive);

      await service.fetchHourlyForecast(51.5, -0.13);

      expect(capturedUri, isNotNull);
      expect(capturedUri!.scheme, 'https');
      expect(capturedUri!.host, 'api.open-meteo.com');
      expect(capturedUri!.path, '/v1/forecast');
      expect(capturedUri!.queryParameters['latitude'], '51.5');
      expect(capturedUri!.queryParameters['longitude'], '-0.13');
      expect(
        capturedUri!.queryParameters['hourly'],
        'temperature_2m,precipitation_probability,windspeed_10m,'
        'relativehumidity_2m,weathercode',
      );
      expect(capturedUri!.queryParameters['daily'], 'sunrise,sunset');
      expect(capturedUri!.queryParameters['timezone'], 'auto');
      expect(capturedUri!.queryParameters['forecast_days'], '7');
    });

    test('should return a non-stale result and persist the response '
        'when api succeeds', () async {
      final client = MockClient(
        (request) async => http.Response(_validApiBody(), 200),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(51.5, -0.13);
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);

      expect(result.isStale, isFalse);
      expect(result.latitude, 51.5);
      expect(result.longitude, -0.13);
      expect(result.timezone, 'Europe/London');
      expect(result.hourlyForecasts, hasLength(2));
      expect(result.sunrises, hasLength(2));
      expect(box.get('forecast'), isNotNull);
      expect(box.get('forecast_timestamp'), isA<int>());
      expect(box.get('forecast_lat'), 51.5);
      expect(box.get('forecast_lng'), -0.13);
    });

    test('should return a fresh cached result without calling the api '
        'when cache matches', () async {
      var apiCallCount = 0;
      final client = MockClient((request) async {
        apiCallCount++;
        return http.Response(_validApiBody(), 200);
      });
      final service = WeatherService(httpClient: client, hive: Hive);

      await service.fetchHourlyForecast(51.5, -0.13);
      final cached = await service.fetchHourlyForecast(51.5, -0.13);

      expect(apiCallCount, 1);
      expect(cached.isStale, isFalse);
      expect(cached.latitude, 51.5);
    });

    test('should return a fresh cached result '
        'when the location is within tolerance', () async {
      var apiCallCount = 0;
      final client = MockClient((request) async {
        apiCallCount++;
        return http.Response(_validApiBody(), 200);
      });
      final service = WeatherService(httpClient: client, hive: Hive);

      await service.fetchHourlyForecast(51.5, -0.13);
      final cached = await service.fetchHourlyForecast(51.509, -0.121);

      expect(apiCallCount, 1);
      expect(cached.isStale, isFalse);
    });

    test(
      'should call the api when cached data is older than thirty minutes',
      () async {
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _seedCache(box, age: const Duration(minutes: 31));

        var apiCallCount = 0;
        final client = MockClient((request) async {
          apiCallCount++;
          return http.Response(_validApiBody(), 200);
        });
        final service = WeatherService(httpClient: client, hive: Hive);

        final result = await service.fetchHourlyForecast(51.5, -0.13);

        expect(apiCallCount, 1);
        expect(result.isStale, isFalse);
      },
    );

    test('should call the api when cached coordinates differ '
        'by more than tolerance', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(box);

      var apiCallCount = 0;
      final client = MockClient((request) async {
        apiCallCount++;
        return http.Response(_validApiBody(latitude: 52, longitude: 0), 200);
      });
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(52, 0);

      expect(apiCallCount, 1);
      expect(result.latitude, 52);
      expect(result.isStale, isFalse);
    });

    test('should return stale cached data when the network request throws '
        'and stale cache exists', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(box, age: const Duration(minutes: 31));

      final client = MockClient(
        (request) async => throw Exception('Network error'),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(51.5, -0.13);

      expect(result.isStale, isTrue);
      expect(result.latitude, 51.5);
      expect(result.forecast.latitude, 51.5);
    });

    test('should return stale cached data when the api returns a bad status '
        'and stale cache exists', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(box, age: const Duration(minutes: 31));

      final client = MockClient(
        (request) async => http.Response('Server error', 500),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(51.5, -0.13);

      expect(result.isStale, isTrue);
    });

    test('should return stale cached data when api response parsing fails '
        'and stale cache exists', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(box, age: const Duration(minutes: 31));

      final client = MockClient(
        (request) async => http.Response('{"hourly":null}', 200),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(51.5, -0.13);

      expect(result.isStale, isTrue);
      expect(result.hourlyForecasts, isNotEmpty);
    });

    test('should fetch from the api when fresh cache json is corrupt '
        'and network succeeds', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(box, rawForecast: 'not-valid-json{{{');

      var apiCallCount = 0;
      final client = MockClient((request) async {
        apiCallCount++;
        return http.Response(_validApiBody(), 200);
      });
      final service = WeatherService(httpClient: client, hive: Hive);

      final result = await service.fetchHourlyForecast(51.5, -0.13);

      expect(apiCallCount, 1);
      expect(result.isStale, isFalse);
      expect(result.latitude, 51.5);
    });

    test('should throw WeatherFetchException when network fails '
        'and no matching cache exists', () async {
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _seedCache(
        box,
        lat: 40,
        lng: -74,
        age: const Duration(minutes: 31),
      );

      final client = MockClient(
        (request) async => throw Exception('Network error'),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      expect(
        () => service.fetchHourlyForecast(51.5, -0.13),
        throwsA(isA<WeatherFetchException>()),
      );
    });

    test('should throw WeatherFetchException with coordinates and cause '
        'when api fails without cache', () async {
      final client = MockClient(
        (request) async => http.Response('Server error', 500),
      );
      final service = WeatherService(httpClient: client, hive: Hive);

      await expectLater(
        service.fetchHourlyForecast(51.5, -0.13),
        throwsA(
          isA<WeatherFetchException>()
              .having((error) => error.message, 'message', contains('51.5'))
              .having((error) => error.message, 'message', contains('-0.13'))
              .having((error) => error.message, 'message', contains('Cause:'))
              .having((error) => error.message, 'message', contains('500')),
        ),
      );
    });
  });
}
