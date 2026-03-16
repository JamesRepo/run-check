class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      displayName: json['displayName'] as String,
    );
  }

  final double latitude;
  final double longitude;
  final String displayName;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'displayName': displayName,
    };
  }

  static double _parseDouble(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toDouble();
    }

    throw FormatException('Expected numeric value, got: $value');
  }
}
