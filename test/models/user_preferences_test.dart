import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/user_preferences.dart';

void main() {
  group('[Unit] UserPreferences', () {
    test('should use the documented defaults when constructed', () {
      final preferences = UserPreferences();

      expect(preferences.unit, TemperatureUnit.celsius);
      expect(
        preferences.preferredPeriods,
        UserPreferences.defaultPreferredPeriods,
      );
      expect(preferences.runDurationMinutes, 60);
      expect(preferences.cyclistMode, isFalse);
    });

    test(
      'should deserialize valid saved preferences when json is complete',
      () {
        final preferences = UserPreferences.fromJson({
          'unit': 'fahrenheit',
          'preferredPeriods': ['morning', 'evening'],
          'runDurationMinutes': 90,
          'cyclistMode': true,
        });

        expect(preferences.unit, TemperatureUnit.fahrenheit);
        expect(preferences.preferredPeriods, ['morning', 'evening']);
        expect(preferences.runDurationMinutes, 90);
        expect(preferences.cyclistMode, isTrue);
      },
    );

    test('should fall back to defaults when saved json values are invalid', () {
      final preferences = UserPreferences.fromJson({
        'unit': 'kelvin',
        'preferredPeriods': ['morning', 42],
        'runDurationMinutes': 'sixty',
      });

      expect(preferences.unit, TemperatureUnit.celsius);
      expect(preferences.preferredPeriods, ['morning']);
      expect(preferences.runDurationMinutes, 60);
      expect(preferences.cyclistMode, isFalse);
    });

    test('should serialize all persisted fields when toJson is called', () {
      final preferences = UserPreferences(
        unit: TemperatureUnit.fahrenheit,
        preferredPeriods: ['afternoon'],
        runDurationMinutes: 45,
        cyclistMode: true,
      );

      expect(preferences.toJson(), {
        'unit': 'fahrenheit',
        'preferredPeriods': ['afternoon'],
        'runDurationMinutes': 45,
        'cyclistMode': true,
      });
    });

    test(
      'should create an unmodifiable preferred periods list when copied',
      () {
        final preferences = UserPreferences().copyWith(
          preferredPeriods: ['evening'],
        );

        expect(preferences.preferredPeriods, ['evening']);
        expect(
          () => preferences.preferredPeriods.add('morning'),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'should store an unmodifiable preferred periods list when constructed',
      () {
        final originalPeriods = <String>['morning'];
        final preferences = UserPreferences(preferredPeriods: originalPeriods);

        originalPeriods.add('evening');

        expect(preferences.preferredPeriods, ['morning']);
        expect(
          () => preferences.preferredPeriods.add('afternoon'),
          throwsUnsupportedError,
        );
      },
    );
  });
}
