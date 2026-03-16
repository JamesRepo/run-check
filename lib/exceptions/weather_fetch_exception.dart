class WeatherFetchException implements Exception {
  const WeatherFetchException(this.message);

  final String message;

  @override
  String toString() => 'WeatherFetchException: $message';
}
