import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';

class ForecastResponse {
  ForecastResponse({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.hourlyForecasts,
    List<SunriseSunset>? dailySunData,
    List<DateTime>? sunrises,
    List<DateTime>? sunsets,
    this.isStale = false,
  })  : assert(
          dailySunData == null || (sunrises == null && sunsets == null),
          'Provide either dailySunData or sunrises/sunsets, not both.',
        ),
        dailySunData = List<SunriseSunset>.unmodifiable(
          dailySunData ??
              _buildDailySunData(
                sunrises: sunrises,
                sunsets: sunsets,
              ),
        );

  factory ForecastResponse.fromJson(
    Map<String, dynamic> json, {
    bool isStale = false,
  }) {
    final hourly = json['hourly'] as Map<String, dynamic>;

    final times = (hourly['time'] as List<dynamic>? ?? <dynamic>[])
        .cast<String>();
    final temperatures = hourly['temperature_2m'] as List<dynamic>? ??
        <dynamic>[];
    final precipitationProbabilities =
        hourly['precipitation_probability'] as List<dynamic>? ?? <dynamic>[];
    final windSpeeds = hourly['windspeed_10m'] as List<dynamic>? ??
        <dynamic>[];
    final humidities = hourly['relativehumidity_2m'] as List<dynamic>? ??
        <dynamic>[];
    final weatherCodes = hourly['weathercode'] as List<dynamic>? ??
        <dynamic>[];

    final entryCount = [
      times.length,
      temperatures.length,
      precipitationProbabilities.length,
      windSpeeds.length,
      humidities.length,
      weatherCodes.length,
    ].reduce((value, element) => value < element ? value : element);

    final hourlyForecasts = List<HourlyForecast>.generate(entryCount, (index) {
      return HourlyForecast.fromJson({
        'time': times[index],
        'temperature_2m': temperatures[index],
        'precipitation_probability': precipitationProbabilities[index],
        'windspeed_10m': windSpeeds[index],
        'relativehumidity_2m': humidities[index],
        'weathercode': weatherCodes[index],
      });
    }, growable: false);

    final daily = json['daily'] as Map<String, dynamic>?;
    final dailyTimes = (daily?['time'] as List<dynamic>? ?? <dynamic>[])
        .cast<String>();
    final sunrises = (daily?['sunrise'] as List<dynamic>? ?? <dynamic>[])
        .cast<String>();
    final sunsets = (daily?['sunset'] as List<dynamic>? ?? <dynamic>[])
        .cast<String>();

    final dailyEntryCount = [
      dailyTimes.length,
      sunrises.length,
      sunsets.length,
    ].reduce((value, element) => value < element ? value : element);

    final dailySunData = List<SunriseSunset>.generate(dailyEntryCount, (index) {
      return SunriseSunset.fromJson({
        'time': dailyTimes[index],
        'sunrise': sunrises[index],
        'sunset': sunsets[index],
      });
    }, growable: false);

    return ForecastResponse(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      timezone: json['timezone'] as String,
      hourlyForecasts: hourlyForecasts,
      dailySunData: dailySunData,
      isStale: isStale,
    );
  }

  final double latitude;
  final double longitude;
  final String timezone;
  final List<HourlyForecast> hourlyForecasts;
  final List<SunriseSunset> dailySunData;
  final bool isStale;

  List<DateTime> get sunrises =>
      dailySunData.map((sunData) => sunData.sunrise).toList(growable: false);

  List<DateTime> get sunsets =>
      dailySunData.map((sunData) => sunData.sunset).toList(growable: false);

  ForecastResponse copyWith({bool? isStale}) {
    return ForecastResponse(
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      hourlyForecasts: hourlyForecasts,
      dailySunData: dailySunData,
      isStale: isStale ?? this.isStale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'hourly': {
        'time': hourlyForecasts
            .map((forecast) => forecast.dateTime.toIso8601String())
            .toList(),
        'temperature_2m': hourlyForecasts
            .map((forecast) => forecast.temperature)
            .toList(),
        'precipitation_probability': hourlyForecasts
            .map((forecast) => forecast.precipitationProbability)
            .toList(),
        'windspeed_10m': hourlyForecasts
            .map((forecast) => forecast.windSpeed)
            .toList(),
        'relativehumidity_2m': hourlyForecasts
            .map((forecast) => forecast.humidity)
            .toList(),
        'weathercode': hourlyForecasts
            .map((forecast) => forecast.weatherCode)
            .toList(),
      },
      'daily': {
        'time': dailySunData
            .map((sunData) => sunData.date.toIso8601String())
            .toList(),
        'sunrise': dailySunData
            .map((sunData) => sunData.sunrise.toIso8601String())
            .toList(),
        'sunset': dailySunData
            .map((sunData) => sunData.sunset.toIso8601String())
            .toList(),
      },
    };
  }

  static List<SunriseSunset> _buildDailySunData({
    List<DateTime>? sunrises,
    List<DateTime>? sunsets,
  }) {
    final sunriseValues = sunrises ?? const <DateTime>[];
    final sunsetValues = sunsets ?? const <DateTime>[];
    final entryCount = sunriseValues.length < sunsetValues.length
        ? sunriseValues.length
        : sunsetValues.length;

    return List<SunriseSunset>.generate(entryCount, (index) {
      final sunrise = sunriseValues[index];
      final sunset = sunsetValues[index];

      return SunriseSunset(
        date: DateTime(sunrise.year, sunrise.month, sunrise.day),
        sunrise: sunrise,
        sunset: sunset,
      );
    }, growable: false);
  }

  static double _parseDouble(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toDouble();
    }

    throw FormatException('Expected numeric value, got: $value');
  }
}
