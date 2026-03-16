import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';

class WeatherResult {
  const WeatherResult({required this.forecast, required this.isStale});

  final ForecastResponse forecast;
  final bool isStale;

  double get latitude => forecast.latitude;
  double get longitude => forecast.longitude;
  String get timezone => forecast.timezone;
  List<HourlyForecast> get hourlyForecasts => forecast.hourlyForecasts;
  List<SunriseSunset> get dailySunData => forecast.dailySunData;
  List<DateTime> get sunrises => forecast.sunrises;
  List<DateTime> get sunsets => forecast.sunsets;
}
