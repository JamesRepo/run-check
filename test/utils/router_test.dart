import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/app.dart';
import 'package:run_check/models/schedule_state.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/services/run_scheduler.dart';
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
      'should navigate to results with a slide transition when schedule '
      'data exists',
      (WidgetTester tester) async {
        final container = _createContainerWithScheduleData();
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

        expect(find.text('Your Best Runs'), findsOneWidget);
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

    testWidgets('should deep link to the settings screen', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(goRouterProvider).go('/settings');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RunCastApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
      'should deep link to the results screen when schedule data exists',
      (WidgetTester tester) async {
        final container = _createContainerWithScheduleData();
        addTearDown(container.dispose);
        container.read(goRouterProvider).go('/results');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your Best Runs'), findsOneWidget);
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

  group('[Widget] Router redirect — /results guard', () {
    testWidgets(
      'should redirect /results to / when requestedRuns is 0 and slots '
      'are empty',
      (WidgetTester tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(goRouterProvider).go('/results');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('RunCheck'), findsOneWidget);
        expect(find.text('Tap to set your location'), findsOneWidget);
        expect(find.text('Your Best Runs'), findsNothing);
      },
    );

    testWidgets(
      'should allow /results when schedule data contains slots',
      (WidgetTester tester) async {
        final container = _createContainerWithScheduleData();
        addTearDown(container.dispose);
        container.read(goRouterProvider).go('/results');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your Best Runs'), findsOneWidget);
        expect(find.text('RunCheck'), findsNothing);
      },
    );

    testWidgets(
      'should allow /results when requestedRuns is positive even with '
      'empty slots',
      (WidgetTester tester) async {
        final container = _createContainerWithScheduleData(
          slots: const <TimeSlot>[],
          requestedRuns: 3,
        );
        addTearDown(container.dispose);
        container.read(goRouterProvider).go('/results');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RunCastApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your Best Runs'), findsOneWidget);
        expect(
          find.text('No suitable run windows found this week.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should not redirect when navigating to / or /settings',
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

        expect(find.text('RunCheck'), findsOneWidget);

        router.go('/settings');
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      },
    );
  });
}

// ── Helpers ───────────────────────────────────────────────────

ProviderContainer _createContainerWithScheduleData({
  List<TimeSlot>? slots,
  int? requestedRuns,
}) {
  final effectiveSlots = slots ?? _testSlots;
  final effectiveRequestedRuns = requestedRuns ?? effectiveSlots.length;

  return ProviderContainer(
    overrides: <Override>[
      runSchedulerProvider.overrideWith(
        (ref) => _PreloadedScheduleNotifier(
          ScheduleState(
            slots: effectiveSlots,
            requestedRuns: effectiveRequestedRuns,
          ),
          ref: ref,
          runScheduler: const RunScheduler(),
        ),
      ),
    ],
  );
}

final _testSlots = <TimeSlot>[
  TimeSlot(
    startTime: DateTime(2026, 3, 16, 9),
    endTime: DateTime(2026, 3, 16, 10),
    score: 0.91,
    temperature: 13,
    precipitationProbability: 5,
    windSpeed: 6,
    weatherCode: 1,
    weatherDescription: 'Mainly clear',
  ),
];

// ── Preloaded notifier ───────────────────────────────────────

class _PreloadedScheduleNotifier extends RunSchedulerNotifier {
  _PreloadedScheduleNotifier(
    ScheduleState initial, {
    required super.ref,
    required super.runScheduler,
  }) {
    state = initial;
  }
}
