import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/utils/constants.dart';

class WeatherFetchException implements Exception {
  const WeatherFetchException(this.message);

  final String message;

  @override
  String toString() => 'WeatherFetchException: $message';
}

class WeatherService {
  WeatherService({http.Client? httpClient, HiveInterface? hive})
      : _httpClient = httpClient ?? http.Client(),
        _hive = hive ?? Hive;

  final http.Client _httpClient;
  final HiveInterface _hive;

  static const _boxName = 'weather_cache';
  static const _cacheKey = 'forecast';
  static const _cacheTimestampKey = 'forecast_timestamp';
  static const _cacheLatKey = 'forecast_lat';
  static const _cacheLngKey = 'forecast_lng';

  static const _cacheDuration = Duration(minutes: 30);
  static const _httpTimeout = Duration(seconds: 10);
  static const _locationTolerance = 0.01;

  Future<ForecastResponse> fetchHourlyForecast(
    double lat,
    double lng,
  ) async {
    final box = await _hive.openBox<dynamic>(_boxName);

    final cached = _readCache(box, lat, lng);
    if (cached != null) return cached;

    try {
      final response = await _fetchFromApi(lat, lng);
      await _writeCache(box, response, lat, lng);
      return response;
    } on Exception catch (e) {
      final stale = _readCache(box, lat, lng, ignoreAge: true);
      if (stale != null) return stale.copyWith(isStale: true);

      throw WeatherFetchException(
        'Failed to fetch forecast for ($lat, $lng) and no cached data '
        'is available. Cause: $e',
      );
    }
  }

  Future<ForecastResponse> _fetchFromApi(double lat, double lng) async {
    final uri = Uri.parse(openMeteoBaseUrl).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'hourly':
            'temperature_2m,precipitation_probability,windspeed_10m,'
            'relativehumidity_2m,weathercode',
        'daily': 'sunrise,sunset',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final response = await _httpClient.get(uri).timeout(_httpTimeout);

    if (response.statusCode != 200) {
      throw WeatherFetchException(
        'Open-Meteo API returned status ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ForecastResponse.fromJson(json);
  }

  ForecastResponse? _readCache(
    Box<dynamic> box,
    double lat,
    double lng, {
    bool ignoreAge = false,
  }) {
    final cachedJson = box.get(_cacheKey) as String?;
    if (cachedJson == null) return null;

    final cachedLat = box.get(_cacheLatKey) as double?;
    final cachedLng = box.get(_cacheLngKey) as double?;
    if (cachedLat == null || cachedLng == null) return null;

    if ((lat - cachedLat).abs() > _locationTolerance ||
        (lng - cachedLng).abs() > _locationTolerance) {
      if (!ignoreAge) return null;
    }

    if (!ignoreAge) {
      final timestamp = box.get(_cacheTimestampKey) as int?;
      if (timestamp == null) return null;

      final cachedAt =
          DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
      if (DateTime.now().toUtc().difference(cachedAt) > _cacheDuration) {
        return null;
      }
    }

    try {
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      return ForecastResponse.fromJson(json);
    } on Exception {
      return null;
    }
  }

  Future<void> _writeCache(
    Box<dynamic> box,
    ForecastResponse response,
    double lat,
    double lng,
  ) async {
    await box.putAll(<String, dynamic>{
      _cacheKey: jsonEncode(response.toJson()),
      _cacheTimestampKey: DateTime.now().toUtc().millisecondsSinceEpoch,
      _cacheLatKey: lat,
      _cacheLngKey: lng,
    });
  }
}
