import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/location_state.dart';
import 'package:run_check/models/schedule_state.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/models/weather_state.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/screens/results_screen.dart';
import 'package:run_check/services/location_service.dart';
import 'package:run_check/services/run_scheduler.dart';
import 'package:run_check/services/weather_service.dart';
import 'package:run_check/utils/app_spacing.dart';
import 'package:run_check/utils/theme.dart';
import 'package:run_check/widgets/time_slot_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Widget] ResultsScreen — app bar', () {
    testWidgets('should display title and back arrow', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(find.text('Your Best Runs'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('should center the title when results are shown', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      expect(appBar.centerTitle, isTrue);
    });

    testWidgets(
      'should apply primary container styling to the app bar title and icons',
      (WidgetTester tester) async {
        await _pumpResultsScreen(tester, slots: _twoSlots);

        final title = tester.widget<Text>(find.text('Your Best Runs'));
        final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
        final refreshIcon = tester.widget<Icon>(find.byIcon(Icons.refresh));

        expect(title.style?.color, appTheme.colorScheme.primaryContainer);
        expect(title.style?.fontWeight, FontWeight.w800);
        expect(title.style?.letterSpacing, -0.3);
        expect(backIcon.color, appTheme.colorScheme.primaryContainer);
        expect(refreshIcon.color, appTheme.colorScheme.primaryContainer);
      },
    );

    testWidgets('should display refresh icon button', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsOneWidget);
    });

    testWidgets('should navigate back when back arrow is tapped', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Home Destination'), findsOneWidget);
    });
  });

  group('[Widget] ResultsScreen — results list', () {
    testWidgets('should display the editorial header above the result cards '
        'when slots exist', (WidgetTester tester) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(find.text('OPTIMAL WINDOWS'), findsOneWidget);
      expect(find.text('Recommended for your weekly gallop.'), findsOneWidget);

      final headerTopLeft = tester.getTopLeft(find.text('OPTIMAL WINDOWS'));
      final firstCardTopLeft = tester.getTopLeft(
        find.byType(TimeSlotCard).first,
      );

      expect(headerTopLeft.dy, greaterThan(0));
      expect(firstCardTopLeft.dy, greaterThan(headerTopLeft.dy));
    });

    testWidgets(
      'should not display the editorial header when no slots are returned',
      (WidgetTester tester) async {
        await _pumpResultsScreen(tester, slots: const <TimeSlot>[]);

        expect(find.text('OPTIMAL WINDOWS'), findsNothing);
        expect(find.text('Recommended for your weekly gallop.'), findsNothing);
      },
    );

    testWidgets('should render a TimeSlotCard for each slot', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(find.byType(TimeSlotCard), findsNWidgets(2));
    });

    testWidgets('should render cards with correct rank numbers', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should display slot details on cards', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(
        tester,
        slots: <TimeSlot>[_twoSlots.first],
        requestedRuns: 1,
      );

      expect(find.text('Monday, 16 Mar'), findsOneWidget);
      expect(find.text('09:00 – 10:00'), findsOneWidget);
      expect(find.text('13°C'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
      expect(find.text('6 km/h'), findsOneWidget);
    });

    testWidgets(
      'should display Fahrenheit when user preference is fahrenheit',
      (WidgetTester tester) async {
        await _pumpResultsScreen(
          tester,
          slots: <TimeSlot>[_twoSlots.first],
          requestedRuns: 1,
          unit: TemperatureUnit.fahrenheit,
        );

        // 13°C -> 55.4°F -> rounds to 55
        expect(find.text('55°F'), findsOneWidget);
        expect(find.text('13°C'), findsNothing);
      },
    );

    testWidgets(
      'should use card gap spacing between consecutive result cards',
      (WidgetTester tester) async {
        await _pumpResultsScreen(tester, slots: _twoSlots);

        final paddingWidgets = tester.widgetList<Padding>(
          find.ancestor(
            of: find.byType(TimeSlotCard),
            matching: find.byType(Padding),
          ),
        );

        expect(
          paddingWidgets.any(
            (padding) =>
                padding.padding ==
                const EdgeInsets.only(bottom: AppSpacing.cardGap),
          ),
          isTrue,
        );
      },
    );
  });

  group('[Widget] ResultsScreen — empty state', () {
    testWidgets('should show empty state when no slots returned', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: const <TimeSlot>[]);

      expect(
        find.text('No suitable run windows found this week.'),
        findsOneWidget,
      );
      expect(
        find.text('Try adjusting your preferences or check back tomorrow.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byType(TimeSlotCard), findsNothing);
    });

    testWidgets('should still have a RefreshIndicator in empty state', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: const <TimeSlot>[]);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('[Widget] ResultsScreen — low results note', () {
    testWidgets(
      'should show low results note when fewer slots than requested',
      (WidgetTester tester) async {
        await _pumpResultsScreen(
          tester,
          slots: <TimeSlot>[_twoSlots.first],
          requestedRuns: 3,
        );

        expect(
          find.textContaining('We found 1 good window out of the 3'),
          findsOneWidget,
        );
        expect(
          find.textContaining("It's a tough weather week!"),
          findsOneWidget,
        );
      },
    );

    testWidgets('should pluralise "windows" when more than one slot found', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots, requestedRuns: 5);

      expect(
        find.textContaining('We found 2 good windows out of the 5'),
        findsOneWidget,
      );
    });

    testWidgets(
      'should not show low results note when all requested slots found',
      (WidgetTester tester) async {
        await _pumpResultsScreen(tester, slots: _twoSlots, requestedRuns: 2);

        expect(find.textContaining('We found'), findsNothing);
      },
    );
  });

  group('[Widget] ResultsScreen — stale data banner', () {
    testWidgets('should show stale banner when weather data is stale', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots, isStale: true);

      expect(
        find.text('Using cached forecast. Pull down to refresh.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should not show stale banner when weather data is fresh', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(tester, slots: _twoSlots);

      expect(
        find.text('Using cached forecast. Pull down to refresh.'),
        findsNothing,
      );
    });
  });

  group('[Widget] ResultsScreen — refresh', () {
    testWidgets('should show loading indicator in app bar when refresh button '
        'is tapped', (WidgetTester tester) async {
      final weatherCompleter = Completer<WeatherResult>();

      await _pumpResultsScreen(
        tester,
        slots: _twoSlots,
        location: testLocation,
        weatherService: FakeWeatherService(fetchCompleter: weatherCompleter),
      );

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);

      weatherCompleter.complete(
        WeatherResult(forecast: buildForecastResponse(), isStale: false),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('should restore refresh icon after refresh completes', (
      WidgetTester tester,
    ) async {
      await _pumpResultsScreen(
        tester,
        slots: _twoSlots,
        location: testLocation,
        weatherService: FakeWeatherService(
          weatherResult: WeatherResult(
            forecast: buildForecastResponse(),
            isStale: false,
          ),
        ),
        runScheduler: FakeRunScheduler(slotsToReturn: _twoSlots),
      );

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'should show snackbar when weather fetch fails during refresh',
      (WidgetTester tester) async {
        await _pumpResultsScreen(
          tester,
          slots: _twoSlots,
          location: testLocation,
          weatherService: FakeWeatherService(error: Exception('Network error')),
        );

        await tester.tap(find.byTooltip('Refresh'));
        await tester.pumpAndSettle();

        expect(find.text('Network error'), findsOneWidget);
      },
    );

    testWidgets('should not refresh when location is null', (
      WidgetTester tester,
    ) async {
      final weatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );

      await _pumpResultsScreen(
        tester,
        slots: _twoSlots,
        weatherService: weatherService,
      );

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(weatherService.fetchCallCount, 0);
    });
  });
}

// ── Test data ─────────────────────────────────────────────────

const testLocation = LocationData(
  latitude: 52.2405,
  longitude: -0.9027,
  displayName: 'Northampton, UK',
);

final _twoSlots = <TimeSlot>[
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
  TimeSlot(
    startTime: DateTime(2026, 3, 17, 14),
    endTime: DateTime(2026, 3, 17, 15),
    score: 0.45,
    temperature: 16,
    precipitationProbability: 25,
    windSpeed: 12,
    weatherCode: 2,
    weatherDescription: 'Partly cloudy',
  ),
];

ForecastResponse buildForecastResponse() {
  return ForecastResponse(
    latitude: testLocation.latitude,
    longitude: testLocation.longitude,
    timezone: 'Europe/London',
    hourlyForecasts: <HourlyForecast>[
      HourlyForecast(
        dateTime: DateTime.utc(2026, 3, 16, 9),
        temperature: 13,
        precipitationProbability: 5,
        windSpeed: 6,
        humidity: 55,
        weatherCode: 1,
      ),
      HourlyForecast(
        dateTime: DateTime.utc(2026, 3, 16, 10),
        temperature: 14,
        precipitationProbability: 10,
        windSpeed: 8,
        humidity: 50,
        weatherCode: 1,
      ),
    ],
    dailySunData: <SunriseSunset>[
      SunriseSunset(
        date: DateTime.utc(2026, 3, 16),
        sunrise: DateTime.utc(2026, 3, 16, 6, 20),
        sunset: DateTime.utc(2026, 3, 16, 18, 10),
      ),
    ],
  );
}

// ── Pump helper ───────────────────────────────────────────────

Future<void> _pumpResultsScreen(
  WidgetTester tester, {
  required List<TimeSlot> slots,
  int requestedRuns = 0,
  bool isStale = false,
  TemperatureUnit unit = TemperatureUnit.celsius,
  LocationData? location,
  FakeWeatherService? weatherService,
  FakeRunScheduler? runScheduler,
}) async {
  final effectiveRequestedRuns = requestedRuns == 0
      ? slots.length
      : requestedRuns;

  // Use nested routes so `/results` is a child of `/`, giving
  // the navigator a parent route to pop back to.
  final router = GoRouter(
    initialLocation: '/results',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Center(child: Text('Home Destination')));
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'results',
            builder: (BuildContext context, GoRouterState state) {
              return const ResultsScreen();
            },
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        runSchedulerProvider.overrideWith(
          (ref) => _PreloadedScheduleNotifier(
            ScheduleState(slots: slots, requestedRuns: effectiveRequestedRuns),
            ref: ref,
            runScheduler: runScheduler ?? FakeRunScheduler(),
          ),
        ),
        weatherProvider.overrideWith(
          (ref) => _PreloadedWeatherNotifier(
            WeatherState(forecast: buildForecastResponse(), isStale: isStale),
            weatherService: weatherService ?? FakeWeatherService(),
          ),
        ),
        settingsProvider.overrideWith(
          (ref) => _PreloadedSettingsNotifier(UserPreferences(unit: unit)),
        ),
        locationProvider.overrideWith(
          (ref) => _PreloadedLocationNotifier(
            LocationState(location: location),
            locationService: FakeLocationService(),
          ),
        ),
        sharedPreferencesLoaderProvider.overrideWithValue(
          SharedPreferences.getInstance,
        ),
      ],
      child: MaterialApp.router(theme: appTheme, routerConfig: router),
    ),
  );

  await tester.pump();
}

// ── Preloaded notifiers ───────────────────────────────────────

class _PreloadedScheduleNotifier extends RunSchedulerNotifier {
  _PreloadedScheduleNotifier(
    ScheduleState initial, {
    required super.ref,
    required super.runScheduler,
  }) {
    state = initial;
  }
}

class _PreloadedWeatherNotifier extends WeatherNotifier {
  _PreloadedWeatherNotifier(
    WeatherState initial, {
    required super.weatherService,
  }) {
    state = initial;
  }
}

class _PreloadedSettingsNotifier extends SettingsNotifier {
  _PreloadedSettingsNotifier(UserPreferences initial)
    : super(sharedPreferencesLoader: SharedPreferences.getInstance) {
    state = initial;
  }
}

class _PreloadedLocationNotifier extends LocationNotifier {
  _PreloadedLocationNotifier(
    LocationState initial, {
    required super.locationService,
  }) {
    state = initial;
  }
}

// ── Fakes ─────────────────────────────────────────────────────

class FakeLocationService extends LocationService {
  FakeLocationService() : super();

  @override
  Future<LocationData?> loadLastLocation() async => null;

  @override
  Future<void> saveLastLocation(LocationData location) async {}

  @override
  Future<void> clearLastLocation() async {}
}

class FakeWeatherService extends WeatherService {
  FakeWeatherService({this.weatherResult, this.error, this.fetchCompleter})
    : super();

  final WeatherResult? weatherResult;
  final Exception? error;
  final Completer<WeatherResult>? fetchCompleter;

  int fetchCallCount = 0;

  @override
  Future<WeatherResult> fetchHourlyForecast(double lat, double lng) async {
    fetchCallCount++;

    if (fetchCompleter != null) {
      return fetchCompleter!.future;
    }

    if (error != null) {
      throw error!;
    }

    return weatherResult!;
  }
}

class FakeRunScheduler extends RunScheduler {
  FakeRunScheduler({this.slotsToReturn = const <TimeSlot>[], this.error});

  final List<TimeSlot> slotsToReturn;
  final Exception? error;

  @override
  List<TimeSlot> findBestSlots({
    required List<HourlyForecast> forecasts,
    required int numberOfRuns,
    int runDurationMinutes = 60,
    List<String> preferredPeriods = const <String>[
      'morning',
      'afternoon',
      'evening',
    ],
    List<SunriseSunset>? sunData,
  }) {
    if (error != null) throw error!;
    return slotsToReturn;
  }
}
