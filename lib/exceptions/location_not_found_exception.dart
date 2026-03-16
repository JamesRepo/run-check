class LocationNotFoundException implements Exception {
  LocationNotFoundException(this.query);

  final String query;

  @override
  String toString() => 'LocationNotFoundException: $query';
}
