import 'package:run_check/models/location_data.dart';

class LocationState {
  const LocationState({
    this.location,
    this.isLoading = false,
    this.errorMessage,
  });

  final LocationData? location;
  final bool isLoading;
  final String? errorMessage;

  static const _sentinel = Object();

  LocationState copyWith({
    Object? location = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return LocationState(
      location: identical(location, _sentinel)
          ? this.location
          : location as LocationData?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
