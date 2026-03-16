class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.temperature,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.weatherCode,
    required this.weatherDescription,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      score: _parseDouble(json['score']),
      temperature: _parseDouble(json['temperature']),
      precipitationProbability: _parseInt(
        json['precipitation_probability'],
      ),
      windSpeed: _parseDouble(json['wind_speed']),
      weatherCode: _parseInt(json['weather_code']),
      weatherDescription: json['weather_description'] as String,
    );
  }

  final DateTime startTime;
  final DateTime endTime;
  final double score;
  final double temperature;
  final int precipitationProbability;
  final double windSpeed;
  final int weatherCode;
  final String weatherDescription;

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'score': score,
      'temperature': temperature,
      'precipitation_probability': precipitationProbability,
      'wind_speed': windSpeed,
      'weather_code': weatherCode,
      'weather_description': weatherDescription,
    };
  }

  static double _parseDouble(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toDouble();
    }

    throw FormatException('Expected numeric value, got: $value');
  }

  static int _parseInt(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toInt();
    }

    throw FormatException('Expected numeric value, got: $value');
  }
}
