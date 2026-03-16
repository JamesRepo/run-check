import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/services/weather_cache_service.dart';

Map<String, dynamic> _forecastJson({
  double latitude = 51.5,
  double longitude = -0.13,
}) {
  return {
    'latitude': latitude,
    'longitude': longitude,
    'timezone': 'Europe/London',
    'hourly': {
      'time': ['2026-03-16T09:00'],
      'temperature_2m': [12.4],
      'precipitation_probability': [30],
      'windspeed_10m': [16.5],
      'relativehumidity_2m': [65.0],
      'weathercode': [3],
    },
    'daily': {
      'time': ['2026-03-16'],
      'sunrise': ['2026-03-16T06:15'],
      'sunset': ['2026-03-16T18:10'],
    },
  };
}

Future<void> _writeRawCache(
  Box<dynamic> box, {
  required double lat,
  required double lng,
  Duration age = Duration.zero,
  String? forecastJson,
  int? timestamp,
}) async {
  await box.putAll(<String, dynamic>{
    'forecast':
        forecastJson ??
        jsonEncode(_forecastJson(latitude: lat, longitude: lng)),
    'forecast_timestamp':
        timestamp ??
        DateTime.now().toUtc().subtract(age).millisecondsSinceEpoch,
    'forecast_lat': lat,
    'forecast_lng': lng,
  });
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync(
      'weather_cache_service_test_',
    );
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

  group('[Unit] WeatherCacheService', () {
    test('should save forecast json timestamp and coordinates '
        'when saving a forecast', () async {
      final service = WeatherCacheService(hive: Hive);
      final forecast = ForecastResponse.fromJson(_forecastJson());

      await service.saveForecast(forecast, 51.5, -0.13);

      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      final rawForecast = box.get('forecast') as String?;
      final decoded = jsonDecode(rawForecast!) as Map<String, dynamic>;

      expect(decoded['latitude'], 51.5);
      expect(box.get('forecast_timestamp'), isA<int>());
      expect(box.get('forecast_lat'), 51.5);
      expect(box.get('forecast_lng'), -0.13);
    });

    test(
      'should return a forecast when cached location matches and data is fresh',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _writeRawCache(box, lat: 51.5, lng: -0.13);

        final forecast = await service.getFreshForecast(51.5, -0.13);

        expect(forecast, isNotNull);
        expect(forecast!.timezone, 'Europe/London');
      },
    );

    test(
      'should return a forecast when cached location is within tolerance',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _writeRawCache(box, lat: 51.5, lng: -0.13);

        final forecast = await service.getFreshForecast(51.509, -0.121);

        expect(forecast, isNotNull);
      },
    );

    test(
      'should return null when cached location differs by more than tolerance',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _writeRawCache(box, lat: 51.5, lng: -0.13);

        final forecast = await service.getFreshForecast(51.511, -0.13);

        expect(forecast, isNull);
      },
    );

    test('should return null when cached forecast is older than thirty minutes '
        'for fresh lookup', () async {
      final service = WeatherCacheService(hive: Hive);
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _writeRawCache(
        box,
        lat: 51.5,
        lng: -0.13,
        age: const Duration(minutes: 31),
      );

      final forecast = await service.getFreshForecast(51.5, -0.13);

      expect(forecast, isNull);
    });

    test('should return stale cached forecast regardless of age '
        'when cached lookup matches', () async {
      final service = WeatherCacheService(hive: Hive);
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _writeRawCache(
        box,
        lat: 51.5,
        lng: -0.13,
        age: const Duration(days: 2),
      );

      final forecast = await service.getCachedForecast(51.5, -0.13);

      expect(forecast, isNotNull);
    });

    test(
      'should return null when timestamp is missing for fresh lookup',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await box.putAll(<String, dynamic>{
          'forecast': jsonEncode(_forecastJson()),
          'forecast_lat': 51.5,
          'forecast_lng': -0.13,
        });

        final forecast = await service.getFreshForecast(51.5, -0.13);

        expect(forecast, isNull);
      },
    );

    test(
      'should return null when required cached fields are missing',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await box.put('forecast', jsonEncode(_forecastJson()));

        final forecast = await service.getCachedForecast(51.5, -0.13);

        expect(forecast, isNull);
      },
    );

    test('should return null when cached forecast json is invalid', () async {
      final service = WeatherCacheService(hive: Hive);
      final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
      await _writeRawCache(
        box,
        lat: 51.5,
        lng: -0.13,
        forecastJson: 'not-json',
      );

      final forecast = await service.getCachedForecast(51.5, -0.13);

      expect(forecast, isNull);
    });

    test(
      'should return null when fresh cached json has an invalid schema',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _writeRawCache(
          box,
          lat: 51.5,
          lng: -0.13,
          forecastJson: jsonEncode(<String, dynamic>{
            'latitude': 51.5,
            'longitude': -0.13,
            'timezone': 'Europe/London',
            'hourly': null,
          }),
        );

        final forecast = await service.getFreshForecast(51.5, -0.13);

        expect(forecast, isNull);
      },
    );

    test(
      'should return null when stale cached json has an invalid schema',
      () async {
        final service = WeatherCacheService(hive: Hive);
        final box = await Hive.openBox<dynamic>(WeatherCacheService.boxName);
        await _writeRawCache(
          box,
          lat: 51.5,
          lng: -0.13,
          age: const Duration(days: 1),
          forecastJson: jsonEncode(<String, dynamic>{
            'latitude': 51.5,
            'longitude': -0.13,
            'timezone': 'Europe/London',
            'hourly': null,
          }),
        );

        final forecast = await service.getCachedForecast(51.5, -0.13);

        expect(forecast, isNull);
      },
    );
  });
}
