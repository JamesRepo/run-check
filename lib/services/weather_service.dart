import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:run_check/exceptions/weather_fetch_exception.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/services/weather_cache_service.dart';
import 'package:run_check/utils/constants.dart';

export 'package:run_check/exceptions/weather_fetch_exception.dart';

class WeatherService {
  WeatherService({
    http.Client? httpClient,
    WeatherCacheService? cacheService,
    HiveInterface? hive,
  }) : _httpClient = httpClient ?? http.Client(),
       _cacheService = cacheService ?? WeatherCacheService(hive: hive);

  final http.Client _httpClient;
  final WeatherCacheService _cacheService;

  static const _httpTimeout = Duration(seconds: 10);

  Future<WeatherResult> fetchHourlyForecast(double lat, double lng) async {
    final freshCache = await _cacheService.getFreshForecast(lat, lng);
    if (freshCache != null) {
      return WeatherResult(forecast: freshCache, isStale: false);
    }

    try {
      final forecast = await _fetchFromApi(lat, lng);
      await _cacheService.saveForecast(forecast, lat, lng);

      return WeatherResult(forecast: forecast, isStale: false);
    } on Object catch (error) {
      final staleCache = await _cacheService.getCachedForecast(lat, lng);
      if (staleCache != null) {
        return WeatherResult(forecast: staleCache, isStale: true);
      }

      throw WeatherFetchException(
        'Failed to fetch forecast for ($lat, $lng). '
        'No cached data is available. Cause: $error',
      );
    }
  }

  Future<ForecastResponse> _fetchFromApi(double lat, double lng) async {
    final uri = Uri.parse(openMeteoBaseUrl).replace(
      queryParameters: <String, String>{
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
}
