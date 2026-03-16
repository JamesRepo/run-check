import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/app.dart';
import 'package:run_check/utils/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Unit] goRouterProvider', () {
    test('should return the same router instance when read multiple times', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstRouter = container.read(goRouterProvider);
      final secondRouter = container.read(goRouterProvider);

      expect(identical(firstRouter, secondRouter), isTrue);
    });
  });

  group('[Widget] RunCastApp routing', () {
    testWidgets('should render the home screen when app starts', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(goRouterProvider).go('/');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RunCastApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RunCheck'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Tap to set your location'), findsOneWidget);
    });

    testWidgets(
      'should navigate to results with a slide transition when routed',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final router = container.read(goRouterProvider)..go('/');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        router.go('/results');
        await tester.pumpAndSettle();

        expect(find.text('Results'), findsOneWidget);
        expect(find.byType(SlideTransition), findsWidgets);
      },
    );

    testWidgets(
      'should navigate to settings with a fade transition when routed',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final router = container.read(goRouterProvider)..go('/');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        router.go('/settings');
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.byType(FadeTransition), findsWidgets);
      },
    );

    testWidgets(
      'should render the expected screen when deep linked to each route',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final router = container.read(goRouterProvider);

        Future<void> pumpRoute(String location) async {
          router.go(location);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const RunCastApp(),
            ),
          );
          await tester.pumpAndSettle();
        }

        await pumpRoute('/results');
        expect(find.text('Results'), findsOneWidget);

        await pumpRoute('/settings');
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets('should expose the configured GoRouter on MaterialApp.router', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(goRouterProvider)..go('/');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RunCastApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.routerConfig, same(router));
    });
  });
}
