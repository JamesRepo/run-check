import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/models/location_state.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/services/location_service.dart';

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    final locationService = ref.watch(locationServiceProvider);
    return LocationNotifier(locationService: locationService);
  },
);

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier({required LocationService locationService})
    : _locationService = locationService,
      super(const LocationState()) {
    unawaited(_loadSavedLocation());
  }

  final LocationService _locationService;
  int _stateVersion = 0;

  Future<void> detectCurrentLocation() async {
    final operationVersion = _beginOperation();
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final location = await _locationService.getCurrentLocation();
      await _locationService.saveLastLocation(location);
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        location: location,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> searchLocation(String query) async {
    final operationVersion = _beginOperation();
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final location = await _locationService.searchLocation(query);
      await _locationService.saveLastLocation(location);
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        location: location,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> clearLocation() async {
    final operationVersion = _beginOperation();
    try {
      await _locationService.clearLastLocation();
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        location: null,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  Future<void> _loadSavedLocation() async {
    final operationVersion = _stateVersion;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final location = await _locationService.loadLastLocation();
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        location: location,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  String _formatError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  int _beginOperation() {
    return ++_stateVersion;
  }

  bool _isCurrentOperation(int operationVersion) {
    return operationVersion == _stateVersion;
  }
}
