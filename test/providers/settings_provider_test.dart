import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Unit] SettingsProvider', () {
    test('should load saved preferences when persisted values exist', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences': jsonEncode({
          'unit': 'fahrenheit',
          'preferredPeriods': ['morning', 'evening'],
          'runDurationMinutes': 90,
          'cyclistMode': true,
        }),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await flushAsyncWork();

      final state = container.read(settingsProvider);
      expect(state.unit, TemperatureUnit.fahrenheit);
      expect(state.preferredPeriods, ['morning', 'evening']);
      expect(state.runDurationMinutes, 90);
      expect(state.cyclistMode, isTrue);
    });

    test(
      'should keep defaults when persisted preferences are missing',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(settingsProvider);
        await flushAsyncWork();

        final state = container.read(settingsProvider);
        expect(state.unit, TemperatureUnit.celsius);
        expect(state.preferredPeriods, ['morning', 'afternoon', 'evening']);
        expect(state.runDurationMinutes, 60);
        expect(state.cyclistMode, isFalse);
      },
    );

    test(
      'should update the unit and persist it when setUnit is called',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(settingsProvider.notifier)
            .setUnit(TemperatureUnit.fahrenheit);

        final state = container.read(settingsProvider);
        final preferences = await SharedPreferences.getInstance();

        expect(state.unit, TemperatureUnit.fahrenheit);
        expect(
          jsonDecode(preferences.getString('user_preferences')!)
              as Map<String, dynamic>,
          containsPair('unit', 'fahrenheit'),
        );
      },
    );

    test('should update the preferred periods and duration '
        'when setters are called', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setPreferredPeriods([
        'evening',
      ]);
      await container.read(settingsProvider.notifier).setRunDuration(45);

      final state = container.read(settingsProvider);
      expect(state.preferredPeriods, ['evening']);
      expect(state.runDurationMinutes, 45);
    });

    test(
      'should update cyclist mode and persist it when setter is called',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(settingsProvider.notifier)
            .setCyclistMode(cyclistMode: true);

        final state = container.read(settingsProvider);
        final preferences = await SharedPreferences.getInstance();

        expect(state.cyclistMode, isTrue);
        expect(
          jsonDecode(preferences.getString('user_preferences')!)
              as Map<String, dynamic>,
          containsPair('cyclistMode', true),
        );
      },
    );

    test(
      'should keep newer settings when saved hydration finishes later',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode({
            'unit': 'celsius',
            'preferredPeriods': ['morning'],
            'runDurationMinutes': 30,
            'cyclistMode': false,
          }),
        });

        final sharedPreferences = await SharedPreferences.getInstance();
        final loaderCompleter = Completer<SharedPreferences>();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesLoaderProvider.overrideWithValue(
              () => loaderCompleter.future,
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(settingsProvider);
        final updateFuture = container
            .read(settingsProvider.notifier)
            .setUnit(TemperatureUnit.fahrenheit);
        loaderCompleter.complete(sharedPreferences);
        await updateFuture;
        await flushAsyncWork();

        final state = container.read(settingsProvider);
        expect(state.unit, TemperatureUnit.fahrenheit);
        expect(state.preferredPeriods, ['morning', 'afternoon', 'evening']);
        expect(state.runDurationMinutes, 60);
        expect(state.cyclistMode, isFalse);
      },
    );
  });

  group('[Widget] SettingsProvider', () {
    testWidgets('should rebuild the widget when cyclist mode is toggled', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: _SettingsConsumerWidget()),
        ),
      );

      expect(find.text('runner'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      expect(find.text('cyclist'), findsOneWidget);
    });
  });
}

class _SettingsConsumerWidget extends ConsumerWidget {
  const _SettingsConsumerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          Text(preferences.cyclistMode ? 'cyclist' : 'runner'),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setCyclistMode(cyclistMode: !preferences.cyclistMode);
            },
            child: const Text('Toggle'),
          ),
        ],
      ),
    );
  }
}

Future<void> flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
