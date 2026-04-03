import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/screens/settings_screen.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Widget] SettingsScreen', () {
    testWidgets(
      'should render the settings sections and controls when opened',
      (WidgetTester tester) async {
        final container = await _pumpSettingsScreen(tester);

        expect(find.text('Settings'), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.text('PREFERENCES'), findsOneWidget);
        expect(find.text('Temperature Unit'), findsOneWidget);
        expect(find.text('Preferred time of day'), findsOneWidget);
        expect(find.text('Typical Run Duration'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Cyclist Mode'),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cyclist Mode'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('ABOUT'),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        expect(find.text('ABOUT'), findsOneWidget);
        expect(find.text('Version 1.0.0'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(container.read(settingsProvider).unit, TemperatureUnit.celsius);
      },
    );

    testWidgets(
      'should reflect persisted preferences when saved settings exist',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode(<String, Object>{
            'unit': 'fahrenheit',
            'preferredPeriods': <String>['afternoon', 'evening'],
            'runDurationMinutes': 90,
            'cyclistMode': true,
          }),
        });

        final container = await _pumpSettingsScreen(tester);
        final chips = tester
            .widgetList<FilterChip>(find.byType(FilterChip))
            .toList();
        final morningChip = chips[0];
        final afternoonChip = chips[1];
        final eveningChip = chips[2];
        await tester.scrollUntilVisible(
          find.byType(SwitchListTile),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );

        expect(
          container.read(settingsProvider).unit,
          TemperatureUnit.fahrenheit,
        );
        expect(container.read(settingsProvider).runDurationMinutes, 90);
        expect(container.read(settingsProvider).preferredPeriods, <String>[
          'afternoon',
          'evening',
        ]);
        expect(container.read(settingsProvider).cyclistMode, isTrue);
        expect(switchTile.value, isTrue);
        expect(afternoonChip.selected, isTrue);
        expect(eveningChip.selected, isTrue);
        expect(morningChip.selected, isFalse);
      },
    );

    testWidgets(
      'should fall back to supported selections when persisted settings '
      'are invalid',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode(<String, Object>{
            'unit': 'fahrenheit',
            'preferredPeriods': <String>[],
            'runDurationMinutes': 75,
            'cyclistMode': true,
          }),
        });

        final container = await _pumpSettingsScreen(tester);

        final durationControl = tester.widget<SegmentedButton<int>>(
          find
              .byWidgetPredicate(
                (Widget widget) => widget is SegmentedButton<int>,
              )
              .first,
        );
        final morningChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Morning (5am-12pm)'),
        );
        final afternoonChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Afternoon (12pm-6pm)'),
        );
        final eveningChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Evening (6pm-9pm)'),
        );

        expect(
          container.read(settingsProvider).preferredPeriods,
          UserPreferences.defaultPreferredPeriods,
        );
        expect(
          container.read(settingsProvider).runDurationMinutes,
          UserPreferences.defaultRunDurationMinutes,
        );
        expect(durationControl.selected, <int>{
          UserPreferences.defaultRunDurationMinutes,
        });
        expect(morningChip.selected, isTrue);
        expect(afternoonChip.selected, isTrue);
        expect(eveningChip.selected, isTrue);
      },
    );

    testWidgets('should update the temperature unit when the fahrenheit '
        'segment is tapped', (WidgetTester tester) async {
      final container = await _pumpSettingsScreen(tester);

      await tester.tap(find.text('°F'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();

      expect(container.read(settingsProvider).unit, TemperatureUnit.fahrenheit);
      expect(
        jsonDecode(preferences.getString('user_preferences')!)
            as Map<String, dynamic>,
        containsPair('unit', 'fahrenheit'),
      );
    });

    testWidgets(
      'should update the preferred periods when an unselected chip is tapped',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode(<String, Object>{
            'unit': 'celsius',
            'preferredPeriods': <String>['evening'],
            'runDurationMinutes': 60,
            'cyclistMode': false,
          }),
        });

        final container = await _pumpSettingsScreen(tester);

        await tester.tap(find.text('Morning (5am-12pm)'));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).preferredPeriods, <String>[
          'morning',
          'evening',
        ]);
      },
    );

    testWidgets(
      'should show a snackbar and keep the last preferred period selected '
      'when the user tries to deselect it',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode(<String, Object>{
            'unit': 'celsius',
            'preferredPeriods': <String>['evening'],
            'runDurationMinutes': 60,
            'cyclistMode': false,
          }),
        });

        final container = await _pumpSettingsScreen(tester);

        await tester.tap(find.text('Evening (6pm-9pm)'));
        await tester.pumpAndSettle();

        final eveningChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Evening (6pm-9pm)'),
        );

        expect(
          find.text('At least one time period must be selected'),
          findsOneWidget,
        );
        expect(container.read(settingsProvider).preferredPeriods, <String>[
          'evening',
        ]);
        expect(eveningChip.selected, isTrue);
      },
    );

    testWidgets(
      'should update the run duration when a new duration segment is tapped',
      (WidgetTester tester) async {
        final container = await _pumpSettingsScreen(tester);

        await tester.scrollUntilVisible(
          find.text('45 min'),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('45 min'));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).runDurationMinutes, 45);
      },
    );

    testWidgets('should update cyclist mode when the switch is toggled', (
      WidgetTester tester,
    ) async {
      final container = await _pumpSettingsScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Cyclist Mode'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cyclist Mode'));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();

      expect(container.read(settingsProvider).cyclistMode, isTrue);
      expect(
        jsonDecode(preferences.getString('user_preferences')!)
            as Map<String, dynamic>,
        containsPair('cyclistMode', true),
      );
    });

    testWidgets(
      'should render the cyclist mode group on the lowest surface container',
      (WidgetTester tester) async {
        await _pumpSettingsScreen(tester);
        await tester.scrollUntilVisible(
          find.text('Cyclist Mode'),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();

        final containerWidget = tester.widget<Container>(
          find.byWidgetPredicate((Widget widget) {
            if (widget is! Container) {
              return false;
            }

            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.color == AppColors.surfaceContainerLowest;
          }).first,
        );
        final decoration = containerWidget.decoration! as BoxDecoration;

        expect(decoration.color, AppColors.surfaceContainerLowest);
      },
    );

    testWidgets(
      'should show a snackbar when the privacy policy tile is tapped',
      (WidgetTester tester) async {
        await _pumpSettingsScreen(tester);

        await tester.scrollUntilVisible(
          find.text('Privacy Policy'),
          200,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        expect(find.text('Privacy policy coming soon'), findsOneWidget);
      },
    );

    testWidgets('should navigate back when the back button is tapped', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsScreen(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });
  });
}

Future<ProviderContainer> _pumpSettingsScreen(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/home/settings',
    routes: <RouteBase>[
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('Home Destination'));
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsScreen();
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: appTheme, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}
