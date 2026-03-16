import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/location_state.dart';

void main() {
  group('[Unit] LocationState', () {
    test('should default to an idle empty state when constructed', () {
      const state = LocationState();

      expect(state.location, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('should update and clear nullable fields when copyWith is used', () {
      const initialState = LocationState(
        location: LocationData(
          latitude: 51.5072,
          longitude: -0.1276,
          displayName: 'London, UK',
        ),
        isLoading: true,
        errorMessage: 'Old error',
      );

      final nextState = initialState.copyWith(
        location: null,
        isLoading: false,
        errorMessage: null,
      );

      expect(nextState.location, isNull);
      expect(nextState.isLoading, isFalse);
      expect(nextState.errorMessage, isNull);
    });
  });
}
