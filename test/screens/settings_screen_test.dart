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
    testWidgets('should render the updated settings copy when opened', (
      WidgetTester tester,
    ) async {
      final container = await _pumpSettingsScreen(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Temperature unit'), findsOneWidget);
      expect(find.text('Preferred time of day'), findsOneWidget);
      expect(find.text('Run duration goal'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('Cyclist mode'), findsOneWidget);
      expect(find.text('Increases wind sensitivity'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ABOUT'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Temperature Unit'), findsNothing);
      expect(find.text('Typical Run Duration'), findsNothing);
      expect(find.text('Cyclist Mode'), findsNothing);
      expect(find.text('Morning (5am-12pm)'), findsNothing);
      expect(find.text('Select when you usually like to train.'), findsNothing);
      expect(container.read(settingsProvider).unit, TemperatureUnit.celsius);
    });

    testWidgets(
      'should use the editorial app bar and setting label styles when opened',
      (WidgetTester tester) async {
        await _pumpSettingsScreen(tester);

        final settingsTitle = tester.widget<Text>(find.text('Settings'));
        final temperatureLabel = tester.widget<Text>(
          find.text('Temperature unit'),
        );

        expect(
          settingsTitle.style?.color,
          appTheme.colorScheme.primaryContainer,
        );
        expect(settingsTitle.style?.fontWeight, FontWeight.w800);
        expect(settingsTitle.style?.letterSpacing, -0.3);
        expect(
          temperatureLabel.style?.color,
          appTheme.colorScheme.onSurfaceVariant,
        );
        expect(temperatureLabel.style?.fontWeight, FontWeight.w500);
        expect(temperatureLabel.style?.fontSize, 14);
      },
    );

    testWidgets(
      'should use the requested unselected control text tokens when opened',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'user_preferences': jsonEncode(<String, Object>{
            'unit': 'celsius',
            'preferredPeriods': <String>['evening'],
            'runDurationMinutes': 60,
            'cyclistMode': false,
          }),
        });

        await _pumpSettingsScreen(tester);

        final fahrenheitLabel = tester.widget<Text>(find.text('°F'));
        final morningLabel = tester.widget<Text>(find.text('Morning'));

        expect(
          fahrenheitLabel.style?.color,
          AppColors.onSecondaryContainerMuted,
        );
        expect(fahrenheitLabel.style?.fontWeight, FontWeight.w500);
        expect(morningLabel.style?.color, AppColors.onSecondaryFixed);
        expect(morningLabel.style?.fontWeight, FontWeight.w500);
      },
    );

    testWidgets(
      'should render the segmented control containers with the requested '
      'decoration when opened',
      (WidgetTester tester) async {
        await _pumpSettingsScreen(tester);

        final temperatureContainer = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('°C'),
                matching: find.byWidgetPredicate((Widget widget) {
                  if (widget is! Container) {
                    return false;
                  }

                  final decoration = widget.decoration;
                  return decoration is BoxDecoration &&
                      decoration.color ==
                          appTheme.colorScheme.secondaryContainer;
                }),
              )
              .first,
        );
        final durationContainer = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('30 min'),
                matching: find.byWidgetPredicate((Widget widget) {
                  if (widget is! Container) {
                    return false;
                  }

                  final decoration = widget.decoration;
                  return decoration is BoxDecoration &&
                      decoration.color ==
                          appTheme.colorScheme.secondaryContainer;
                }),
              )
              .first,
        );

        final temperatureDecoration =
            temperatureContainer.decoration! as BoxDecoration;
        final durationDecoration =
            durationContainer.decoration! as BoxDecoration;

        expect(
          temperatureDecoration.color,
          appTheme.colorScheme.secondaryContainer,
        );
        expect(temperatureDecoration.borderRadius, BorderRadius.circular(9999));
        expect(
          durationDecoration.color,
          appTheme.colorScheme.secondaryContainer,
        );
        expect(durationDecoration.borderRadius, BorderRadius.circular(12));
      },
    );

    testWidgets('should reflect persisted preferences in the custom controls '
        'when saved settings exist', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences': jsonEncode(<String, Object>{
          'unit': 'fahrenheit',
          'preferredPeriods': <String>['afternoon', 'evening'],
          'runDurationMinutes': 90,
          'cyclistMode': true,
        }),
      });

      final container = await _pumpSettingsScreen(tester);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));

      expect(container.read(settingsProvider).unit, TemperatureUnit.fahrenheit);
      expect(container.read(settingsProvider).runDurationMinutes, 90);
      expect(container.read(settingsProvider).preferredPeriods, <String>[
        'afternoon',
        'evening',
      ]);
      expect(container.read(settingsProvider).cyclistMode, isTrue);
      expect(switchWidget.value, isTrue);
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '°F',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '°C',
          color: Colors.transparent,
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.text('°C')).style?.color,
        AppColors.onSecondaryContainerMuted,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Afternoon',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Evening',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Morning',
          color: AppColors.secondaryFixed,
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.text('Morning')).style?.color,
        AppColors.onSecondaryFixed,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '90 min',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should fall back to supported selections when persisted '
        'settings are invalid', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences': jsonEncode(<String, Object>{
          'unit': 'fahrenheit',
          'preferredPeriods': <String>[],
          'runDurationMinutes': 75,
          'cyclistMode': true,
        }),
      });

      final container = await _pumpSettingsScreen(tester);

      expect(
        container.read(settingsProvider).preferredPeriods,
        UserPreferences.defaultPreferredPeriods,
      );
      expect(
        container.read(settingsProvider).runDurationMinutes,
        UserPreferences.defaultRunDurationMinutes,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '30 min',
          color: Colors.transparent,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '45 min',
          color: Colors.transparent,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '60 min',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Morning',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Afternoon',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Evening',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
    });

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
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: '°F',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
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

        await tester.tap(find.text('Morning'));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).preferredPeriods, <String>[
          'morning',
          'evening',
        ]);
        expect(
          _findSelectableMaterialForText(
            tester: tester,
            text: 'Morning',
            color: appTheme.colorScheme.primary,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('should show a snackbar and keep the last preferred period '
        'selected when the user tries to deselect it', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_preferences': jsonEncode(<String, Object>{
          'unit': 'celsius',
          'preferredPeriods': <String>['evening'],
          'runDurationMinutes': 60,
          'cyclistMode': false,
        }),
      });

      final container = await _pumpSettingsScreen(tester);

      await tester.tap(find.text('Evening'));
      await tester.pumpAndSettle();

      expect(
        find.text('At least one time period must be selected'),
        findsOneWidget,
      );
      expect(container.read(settingsProvider).preferredPeriods, <String>[
        'evening',
      ]);
      expect(
        _findSelectableMaterialForText(
          tester: tester,
          text: 'Evening',
          color: appTheme.colorScheme.primary,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'should update the run duration when a new duration segment is tapped',
      (WidgetTester tester) async {
        final container = await _pumpSettingsScreen(tester);

        await tester.tap(find.text('45 min'));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).runDurationMinutes, 45);
        expect(
          _findSelectableMaterialForText(
            tester: tester,
            text: '45 min',
            color: appTheme.colorScheme.primary,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('should update cyclist mode when the switch is toggled', (
      WidgetTester tester,
    ) async {
      final container = await _pumpSettingsScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Cyclist mode'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();

      expect(container.read(settingsProvider).cyclistMode, isTrue);
      expect(
        jsonDecode(preferences.getString('user_preferences')!)
            as Map<String, dynamic>,
        containsPair('cyclistMode', true),
      );
    });

    testWidgets('should render the cyclist mode group on the lowest surface '
        'container when opened', (WidgetTester tester) async {
      await _pumpSettingsScreen(tester);

      final cyclistModeGroup = find.ancestor(
        of: find.text('Cyclist mode'),
        matching: find.byWidgetPredicate((Widget widget) {
          if (widget is! Container) {
            return false;
          }

          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == AppColors.surfaceContainerLowest;
        }),
      );

      expect(cyclistModeGroup, findsOneWidget);
    });

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

Finder _findSelectableMaterialForText({
  required WidgetTester tester,
  required String text,
  required Color color,
}) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((Widget widget) {
      if (widget is! Material) {
        return false;
      }

      return widget.color == color;
    }),
  );
}
