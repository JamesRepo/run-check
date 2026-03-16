import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'
    show GeolocatorPlatform, LocationPermission;
import 'package:run_check/exceptions/location_not_found_exception.dart';
import 'package:run_check/exceptions/location_permission_denied_exception.dart';
import 'package:run_check/exceptions/location_permission_permanently_denied_exception.dart';
import 'package:run_check/exceptions/location_service_disabled_exception.dart';
import 'package:run_check/models/location_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:run_check/exceptions/location_not_found_exception.dart';
export 'package:run_check/exceptions/location_permission_denied_exception.dart';
export 'package:run_check/exceptions/location_permission_permanently_denied_exception.dart';
export 'package:run_check/exceptions/location_service_disabled_exception.dart';

class LocationService {
  LocationService({
    GeolocatorPlatform? geolocatorPlatform,
    SharedPreferences? sharedPreferences,
  }) : _geolocatorPlatform = geolocatorPlatform ?? GeolocatorPlatform.instance,
       _sharedPreferences = sharedPreferences;

  final GeolocatorPlatform _geolocatorPlatform;
  final SharedPreferences? _sharedPreferences;

  static const _lastLocationKey = 'last_location';

  Future<LocationData> getCurrentLocation() async {
    final serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    final displayName = await _buildDisplayName(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      displayName: displayName,
    );
  }

  Future<LocationData> searchLocation(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw LocationNotFoundException(trimmedQuery);
    }

    final locations = await locationsFromAddress(trimmedQuery);
    if (locations.isEmpty) {
      throw LocationNotFoundException(trimmedQuery);
    }

    final location = locations.first;
    final displayName = await _buildDisplayName(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return LocationData(
      latitude: location.latitude,
      longitude: location.longitude,
      displayName: displayName,
    );
  }

  Future<void> saveLastLocation(LocationData location) async {
    final preferences = await _getSharedPreferences();
    await preferences.setString(
      _lastLocationKey,
      jsonEncode(location.toJson()),
    );
  }

  Future<LocationData?> loadLastLocation() async {
    final preferences = await _getSharedPreferences();
    final savedLocation = preferences.getString(_lastLocationKey);
    if (savedLocation == null) {
      return null;
    }

    try {
      final json = jsonDecode(savedLocation) as Map<String, dynamic>;
      return LocationData.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    return _sharedPreferences ?? SharedPreferences.getInstance();
  }

  Future<String> _buildDisplayName({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await placemarksFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) {
      return _formatCoordinateDisplayName(latitude, longitude);
    }

    final placemark = placemarks.first;
    final locality = _firstNonEmpty(<String?>[
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.name,
    ]);
    final country = _firstNonEmpty(<String?>[
      placemark.country,
      placemark.isoCountryCode,
    ]);

    final parts = <String>[
      if (locality != null) locality,
      if (country != null) country,
    ];

    if (parts.isEmpty) {
      return _formatCoordinateDisplayName(latitude, longitude);
    }

    return parts.join(', ');
  }

  Future<List<Location>> locationsFromAddress(String query) {
    return locationFromAddress(query);
  }

  Future<List<Placemark>> placemarksFromCoordinates(
    double latitude,
    double longitude,
  ) {
    return placemarkFromCoordinates(latitude, longitude);
  }

  String _formatCoordinateDisplayName(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}
