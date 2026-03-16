class SunriseSunset {
  const SunriseSunset({
    required this.date,
    required this.sunrise,
    required this.sunset,
  });

  factory SunriseSunset.fromJson(Map<String, dynamic> json) {
    return SunriseSunset(
      date: DateTime.parse(json['time'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      sunset: DateTime.parse(json['sunset'] as String),
    );
  }

  final DateTime date;
  final DateTime sunrise;
  final DateTime sunset;

  Map<String, dynamic> toJson() {
    return {
      'time': date.toIso8601String(),
      'sunrise': sunrise.toIso8601String(),
      'sunset': sunset.toIso8601String(),
    };
  }
}
