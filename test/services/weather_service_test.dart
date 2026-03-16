import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:run_check/services/weather_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

String _validApiBody({
  double latitude = 51.5,
  double longitude = -0.13,
}) =>
    jsonEncode(_validApiJson(latitude: latitude, longitude: longitude));

Future<void> _seedCache(
  Box<dynamic> box, {
  double lat = 51.5,
  double lng = -0.13,
  Duration age = Duration.zero,
}) async {
  final response = _validApiJson(latitude: lat, longitude: lng);
  await box.put('forecast', jsonEncode(response));
  await box.put(
    'forecast_timestamp',
    DateTime.now().toUtc().subtract(age).millisecondsSinceEpoch,
  );
  await box.put('forecast_lat', lat);
  await box.put('forecast_lng', lng);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('weather_service_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  tearDown(() async {
    await Hive.close();
    try {
      await Hive.deleteBoxFromDisk('weather_cache');
    } on Exception catch (_) {
      // Box file might not exist if the test never opened it.
    }
  });

  // -----------------------------------------------------------------------
  // WeatherFetchException
  // -----------------------------------------------------------------------
  group('[Unit] WeatherFetchException', () {
    test('should store the provided message when created', () {
      const exception = WeatherFetchException('something went wrong');

      expect(exception.message, 'something went wrong');
    });

    test(
      'should include the message in toString when converted to string',
      () {
        const exception = WeatherFetchException('timeout');

        expect(
          exception.toString(),
          'WeatherFetchException: timeout',
        );
      },
    );
  });

  // -----------------------------------------------------------------------
  // WeatherService – API request
  // -----------------------------------------------------------------------
  group('[Unit] WeatherService', () {
    group('API request', () {
      test(
        'should send a GET request with correct query parameters '
        'when fetching',
        () async {
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
            contains('temperature_2m'),
          );
          expect(
            capturedUri!.queryParameters['hourly'],
            contains('precipitation_probability'),
          );
          expect(
            capturedUri!.queryParameters['hourly'],
            contains('windspeed_10m'),
          );
          expect(
            capturedUri!.queryParameters['hourly'],
            contains('relativehumidity_2m'),
          );
          expect(
            capturedUri!.queryParameters['hourly'],
            contains('weathercode'),
          );
          expect(capturedUri!.queryParameters['daily'], 'sunrise,sunset');
          expect(capturedUri!.queryParameters['timezone'], 'auto');
          expect(capturedUri!.queryParameters['forecast_days'], '7');
        },
      );

      test(
        'should return a non-stale ForecastResponse with daily data '
        'when API returns 200',
        () async {
          final client = MockClient(
            (request) async => http.Response(_validApiBody(), 200),
          );

          final service = WeatherService(httpClient: client, hive: Hive);
          final response = await service.fetchHourlyForecast(51.5, -0.13);

          expect(response.isStale, isFalse);
          expect(response.latitude, 51.5);
          expect(response.longitude, -0.13);
          expect(response.timezone, 'Europe/London');
          expect(response.hourlyForecasts, hasLength(2));
          expect(response.sunrises, hasLength(2));
          expect(response.sunsets, hasLength(2));
        },
      );
    });

    // ---------------------------------------------------------------------
    // Cache hit
    // ---------------------------------------------------------------------
    group('cache hit', () {
      test(
        'should return cached data without calling API '
        'when cache is fresh and location matches',
        () async {
          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(_validApiBody(), 200);
          });

          final service = WeatherService(httpClient: client, hive: Hive);

          // First call — populates cache.
          await service.fetchHourlyForecast(51.5, -0.13);
          expect(apiCallCount, 1);

          // Second call — should hit cache.
          final cached = await service.fetchHourlyForecast(51.5, -0.13);
          expect(apiCallCount, 1);
          expect(cached.isStale, isFalse);
          expect(cached.latitude, 51.5);
        },
      );

      test(
        'should return cached data when location is within '
        '0.01 degree tolerance',
        () async {
          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(_validApiBody(), 200);
          });

          final service = WeatherService(httpClient: client, hive: Hive);

          // Populate cache at (51.5, -0.13).
          await service.fetchHourlyForecast(51.5, -0.13);
          expect(apiCallCount, 1);

          // Request at exactly 0.01 away — should still be a cache hit.
          await service.fetchHourlyForecast(51.51, -0.13);
          expect(apiCallCount, 1);
        },
      );
    });

    // ---------------------------------------------------------------------
    // Cache miss
    // ---------------------------------------------------------------------
    group('cache miss', () {
      test(
        'should call API when cache is older than 30 minutes',
        () async {
          // Pre-populate cache with a 31-minute-old timestamp.
          final box = await Hive.openBox<dynamic>('weather_cache');
          await _seedCache(box, age: const Duration(minutes: 31));

          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(_validApiBody(), 200);
          });

          final service = WeatherService(httpClient: client, hive: Hive);
          await service.fetchHourlyForecast(51.5, -0.13);

          expect(apiCallCount, 1);
        },
      );

      test(
        'should call API when location differs by more than 0.01 degrees',
        () async {
          // Pre-populate cache at (51.5, -0.13).
          final box = await Hive.openBox<dynamic>('weather_cache');
          await _seedCache(box);

          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(
              _validApiBody(latitude: 52, longitude: 0),
              200,
            );
          });

          final service = WeatherService(httpClient: client, hive: Hive);

          // Request far away from cached location.
          await service.fetchHourlyForecast(52, 0);
          expect(apiCallCount, 1);
        },
      );

      test(
        'should call API when location differs by just over 0.01 degrees',
        () async {
          final box = await Hive.openBox<dynamic>('weather_cache');
          await _seedCache(box);

          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(_validApiBody(), 200);
          });

          final service = WeatherService(httpClient: client, hive: Hive);

          // 0.011 degrees away — should miss the cache.
          await service.fetchHourlyForecast(51.511, -0.13);
          expect(apiCallCount, 1);
        },
      );
    });

    // ---------------------------------------------------------------------
    // Error handling & fallback
    // ---------------------------------------------------------------------
    group('error handling', () {
      test(
        'should return cached data with isStale true '
        'when API throws an exception',
        () async {
          // Populate cache first via a successful call.
          final successClient = MockClient(
            (request) async => http.Response(_validApiBody(), 200),
          );
          var service = WeatherService(httpClient: successClient, hive: Hive);
          await service.fetchHourlyForecast(51.5, -0.13);

          // Now use a failing client.
          final failClient = MockClient(
            (request) async => throw Exception('Network error'),
          );
          service = WeatherService(httpClient: failClient, hive: Hive);

          // Expire the cache so _readCache (without ignoreAge) misses,
          // forcing the API call which will fail.
          final box = Hive.box<dynamic>('weather_cache');
          await box.put(
            'forecast_timestamp',
            DateTime.now()
                .toUtc()
                .subtract(const Duration(minutes: 31))
                .millisecondsSinceEpoch,
          );

          final response = await service.fetchHourlyForecast(51.5, -0.13);

          expect(response.isStale, isTrue);
          expect(response.latitude, 51.5);
        },
      );

      test(
        'should return cached data with isStale true '
        'when API returns non-200',
        () async {
          // Seed a fresh cache then expire it.
          final box = await Hive.openBox<dynamic>('weather_cache');
          await _seedCache(box, age: const Duration(minutes: 31));

          final client = MockClient(
            (request) async => http.Response('Server error', 500),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          final response = await service.fetchHourlyForecast(51.5, -0.13);

          expect(response.isStale, isTrue);
        },
      );

      test(
        'should return stale cached data for a different location '
        'when API fails',
        () async {
          // Cache data for (51.5, -0.13).
          final box = await Hive.openBox<dynamic>('weather_cache');
          await _seedCache(box, age: const Duration(minutes: 31));

          final client = MockClient(
            (request) async => throw Exception('Network error'),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          // Request for a completely different location.
          final response = await service.fetchHourlyForecast(40, -74);

          expect(response.isStale, isTrue);
        },
      );

      test(
        'should skip corrupt cache and fetch from API '
        'when cached JSON is invalid',
        () async {
          // Write corrupt JSON directly into the cache.
          final box = await Hive.openBox<dynamic>('weather_cache');
          await box.putAll(<String, dynamic>{
            'forecast': 'not-valid-json{{{',
            'forecast_timestamp':
                DateTime.now().toUtc().millisecondsSinceEpoch,
            'forecast_lat': 51.5,
            'forecast_lng': -0.13,
          });

          var apiCallCount = 0;
          final client = MockClient((request) async {
            apiCallCount++;
            return http.Response(_validApiBody(), 200);
          });

          final service = WeatherService(httpClient: client, hive: Hive);
          final response = await service.fetchHourlyForecast(51.5, -0.13);

          expect(apiCallCount, 1);
          expect(response.isStale, isFalse);
          expect(response.latitude, 51.5);
        },
      );

      test(
        'should throw WeatherFetchException '
        'when cached JSON is corrupt and API fails',
        () async {
          // Write corrupt JSON directly into the cache.
          final box = await Hive.openBox<dynamic>('weather_cache');
          await box.putAll(<String, dynamic>{
            'forecast': 'not-valid-json{{{',
            'forecast_timestamp':
                DateTime.now().toUtc().millisecondsSinceEpoch,
            'forecast_lat': 51.5,
            'forecast_lng': -0.13,
          });

          final client = MockClient(
            (request) async => throw Exception('Network error'),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          expect(
            () => service.fetchHourlyForecast(51.5, -0.13),
            throwsA(isA<WeatherFetchException>()),
          );
        },
      );

      test(
        'should include original cause in exception message '
        'when API fails and no cache exists',
        () async {
          final client = MockClient(
            (request) async => http.Response('Server error', 500),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          try {
            await service.fetchHourlyForecast(51.5, -0.13);
            fail('Expected WeatherFetchException');
          } on WeatherFetchException catch (e) {
            expect(e.message, contains('Cause:'));
            expect(e.message, contains('500'));
          }
        },
      );

      test(
        'should throw WeatherFetchException '
        'when API fails and no cache exists',
        () async {
          final client = MockClient(
            (request) async => throw Exception('Network error'),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          expect(
            () => service.fetchHourlyForecast(51.5, -0.13),
            throwsA(isA<WeatherFetchException>()),
          );
        },
      );

      test(
        'should throw WeatherFetchException '
        'when API returns non-200 and no cache exists',
        () async {
          final client = MockClient(
            (request) async => http.Response('Not found', 404),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          expect(
            () => service.fetchHourlyForecast(51.5, -0.13),
            throwsA(isA<WeatherFetchException>()),
          );
        },
      );

      test(
        'should include coordinates in exception message '
        'when throwing WeatherFetchException',
        () async {
          final client = MockClient(
            (request) async => throw Exception('Network error'),
          );
          final service = WeatherService(httpClient: client, hive: Hive);

          try {
            await service.fetchHourlyForecast(51.5, -0.13);
            fail('Expected WeatherFetchException');
          } on WeatherFetchException catch (e) {
            expect(e.message, contains('51.5'));
            expect(e.message, contains('-0.13'));
          }
        },
      );
    });
  });
}
