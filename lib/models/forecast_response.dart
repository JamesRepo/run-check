import 'package:run_check/models/hourly_forecast.dart';

class ForecastResponse {
  const ForecastResponse({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.hourlyForecasts,
    required this.sunrises,
    required this.sunsets,
    this.isStale = false,
  });

  factory ForecastResponse.fromJson(
    Map<String, dynamic> json, {
    bool isStale = false,
  }) {
    final hourly = json['hourly'] as Map<String, dynamic>;

    final times = (hourly['time'] as List<dynamic>).cast<String>();
    final temperatures = hourly['temperature_2m'] as List<dynamic>;
    final precipitationProbabilities =
        hourly['precipitation_probability'] as List<dynamic>;
    final windSpeeds = hourly['windspeed_10m'] as List<dynamic>;
    final humidities = hourly['relativehumidity_2m'] as List<dynamic>;
    final weatherCodes = hourly['weathercode'] as List<dynamic>;

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
    });

    final daily = json['daily'] as Map<String, dynamic>?;
    final sunrises = (daily?['sunrise'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList() ??
        [];
    final sunsets = (daily?['sunset'] as List<dynamic>?)
            ?.map((e) => DateTime.parse(e as String))
            .toList() ??
        [];

    return ForecastResponse(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      timezone: json['timezone'] as String,
      hourlyForecasts: hourlyForecasts,
      sunrises: sunrises,
      sunsets: sunsets,
      isStale: isStale,
    );
  }

  final double latitude;
  final double longitude;
  final String timezone;
  final List<HourlyForecast> hourlyForecasts;
  final List<DateTime> sunrises;
  final List<DateTime> sunsets;
  final bool isStale;

  ForecastResponse copyWith({bool? isStale}) {
    return ForecastResponse(
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      hourlyForecasts: hourlyForecasts,
      sunrises: sunrises,
      sunsets: sunsets,
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
        'sunrise':
            sunrises.map((dt) => dt.toIso8601String()).toList(),
        'sunset':
            sunsets.map((dt) => dt.toIso8601String()).toList(),
      },
    };
  }

  static double _parseDouble(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toDouble();
    }

    throw FormatException('Expected numeric value, got: $value');
  }
}
