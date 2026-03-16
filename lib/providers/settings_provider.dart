import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

final sharedPreferencesLoaderProvider = Provider<SharedPreferencesLoader>((
  ref,
) {
  return SharedPreferences.getInstance;
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserPreferences>((ref) {
      final sharedPreferencesLoader = ref.watch(
        sharedPreferencesLoaderProvider,
      );
      return SettingsNotifier(sharedPreferencesLoader: sharedPreferencesLoader);
    });

class SettingsNotifier extends StateNotifier<UserPreferences> {
  SettingsNotifier({required SharedPreferencesLoader sharedPreferencesLoader})
    : _sharedPreferencesLoader = sharedPreferencesLoader,
      super(UserPreferences()) {
    unawaited(_loadPreferences());
  }

  static const _preferencesKey = 'user_preferences';
  final SharedPreferencesLoader _sharedPreferencesLoader;
  int _stateVersion = 0;

  Future<void> setUnit(TemperatureUnit unit) async {
    final operationVersion = _beginOperation();
    final nextState = state.copyWith(unit: unit);
    state = nextState;
    await _savePreferences(nextState, operationVersion: operationVersion);
  }

  Future<void> setPreferredPeriods(List<String> preferredPeriods) async {
    final operationVersion = _beginOperation();
    final nextState = state.copyWith(preferredPeriods: preferredPeriods);
    state = nextState;
    await _savePreferences(nextState, operationVersion: operationVersion);
  }

  Future<void> setRunDuration(int runDurationMinutes) async {
    final operationVersion = _beginOperation();
    final nextState = state.copyWith(runDurationMinutes: runDurationMinutes);
    state = nextState;
    await _savePreferences(nextState, operationVersion: operationVersion);
  }

  Future<void> setCyclistMode({required bool cyclistMode}) async {
    final operationVersion = _beginOperation();
    final nextState = state.copyWith(cyclistMode: cyclistMode);
    state = nextState;
    await _savePreferences(nextState, operationVersion: operationVersion);
  }

  Future<void> _loadPreferences() async {
    final operationVersion = _stateVersion;
    final preferences = await _sharedPreferencesLoader();
    final savedPreferences = preferences.getString(_preferencesKey);
    if (savedPreferences == null) {
      return;
    }

    try {
      final json = jsonDecode(savedPreferences) as Map<String, dynamic>;
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = UserPreferences.fromJson(json);
    } on Object {
      if (!_isCurrentOperation(operationVersion)) {
        return;
      }

      state = UserPreferences();
    }
  }

  Future<void> _savePreferences(
    UserPreferences preferencesState, {
    required int operationVersion,
  }) async {
    final preferences = await _sharedPreferencesLoader();
    if (!_isCurrentOperation(operationVersion)) {
      return;
    }

    await preferences.setString(
      _preferencesKey,
      jsonEncode(preferencesState.toJson()),
    );
  }

  int _beginOperation() {
    return ++_stateVersion;
  }

  bool _isCurrentOperation(int operationVersion) {
    return operationVersion == _stateVersion;
  }
}
