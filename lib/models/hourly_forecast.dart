class HourlyForecast {
  const HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.humidity,
    required this.weatherCode,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      dateTime: DateTime.parse(json['time'] as String),
      temperature: _parseDouble(json['temperature_2m']),
      precipitationProbability: _parseInt(json['precipitation_probability']),
      windSpeed: _parseDouble(json['windspeed_10m']),
      humidity: _parseDouble(json['relativehumidity_2m']),
      weatherCode: _parseInt(json['weathercode']),
    );
  }

  final DateTime dateTime;
  final double temperature;
  final int precipitationProbability;
  final double windSpeed;
  final double humidity;
  final int weatherCode;

  Map<String, dynamic> toJson() {
    return {
      'time': dateTime.toIso8601String(),
      'temperature_2m': temperature,
      'precipitation_probability': precipitationProbability,
      'windspeed_10m': windSpeed,
      'relativehumidity_2m': humidity,
      'weathercode': weatherCode,
    };
  }

  static double _parseDouble(
    Object? value, {
    double defaultValue = 0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value case final num numericValue) {
      return numericValue.toDouble();
    }

    throw FormatException('Expected numeric value, got: $value');
  }

  static int _parseInt(
    Object? value, {
    int defaultValue = 0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value case final num numericValue) {
      return numericValue.toInt();
    }

    throw FormatException('Expected numeric value, got: $value');
  }
}
