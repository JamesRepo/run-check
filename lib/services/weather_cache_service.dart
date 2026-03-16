import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:run_check/models/forecast_response.dart';

class WeatherCacheService {
  WeatherCacheService({HiveInterface? hive}) : _hive = hive ?? Hive;

  final HiveInterface _hive;

  static const boxName = 'weather_cache';
  static const _forecastKey = 'forecast';
  static const _timestampKey = 'forecast_timestamp';
  static const _latitudeKey = 'forecast_lat';
  static const _longitudeKey = 'forecast_lng';
  static const _cacheDuration = Duration(minutes: 30);
  static const _locationTolerance = 0.01;

  Future<ForecastResponse?> getFreshForecast(double lat, double lng) {
    return _readForecast(lat, lng, maxAge: _cacheDuration);
  }

  Future<ForecastResponse?> getCachedForecast(double lat, double lng) {
    return _readForecast(lat, lng);
  }

  Future<void> saveForecast(
    ForecastResponse forecast,
    double lat,
    double lng,
  ) async {
    final box = await _hive.openBox<dynamic>(boxName);
    await box.putAll(<String, dynamic>{
      _forecastKey: jsonEncode(forecast.toJson()),
      _timestampKey: DateTime.now().toUtc().millisecondsSinceEpoch,
      _latitudeKey: lat,
      _longitudeKey: lng,
    });
  }

  Future<ForecastResponse?> _readForecast(
    double lat,
    double lng, {
    Duration? maxAge,
  }) async {
    final box = await _hive.openBox<dynamic>(boxName);
    final cachedJson = box.get(_forecastKey) as String?;
    final cachedLat = box.get(_latitudeKey) as double?;
    final cachedLng = box.get(_longitudeKey) as double?;

    if (cachedJson == null || cachedLat == null || cachedLng == null) {
      return null;
    }

    final isMatchingLocation =
        (lat - cachedLat).abs() <= _locationTolerance &&
        (lng - cachedLng).abs() <= _locationTolerance;
    if (!isMatchingLocation) {
      return null;
    }

    if (maxAge != null) {
      final timestamp = box.get(_timestampKey) as int?;
      if (timestamp == null) {
        return null;
      }

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(
        timestamp,
        isUtc: true,
      );
      if (DateTime.now().toUtc().difference(cachedAt) > maxAge) {
        return null;
      }
    }

    try {
      final json = jsonDecode(cachedJson) as Map<String, dynamic>;
      return ForecastResponse.fromJson(json);
    } on Object {
      return null;
    }
  }
}
