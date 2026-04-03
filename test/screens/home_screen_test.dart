import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/weather_result.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/screens/home_screen.dart';
import 'package:run_check/services/location_service.dart';
import 'package:run_check/services/run_scheduler.dart';
import 'package:run_check/services/weather_service.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Widget] HomeScreen', () {
    testWidgets('should render the placeholder location and disable the CTA '
        'when no location is set', (WidgetTester tester) async {
      await _pumpHomeScreen(tester);

      expect(find.text('RunCheck'), findsOneWidget);
      expect(find.text('Tap to set your location'), findsOneWidget);
      expect(find.text('How many runs this week?'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsOneWidget);

      final cta = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Find my best runs'),
      );
      expect(cta.onPressed, isNull);
    });

    testWidgets('should render the default run count in the wheel selector', (
      WidgetTester tester,
    ) async {
      await _pumpHomeScreen(tester);

      final selectedLabel = tester.widget<Text>(
        find.descendant(
          of: find.byType(ListWheelScrollView),
          matching: find.text('3'),
        ),
      );

      expect(
        selectedLabel.style?.color,
        appTheme.colorScheme.onPrimaryContainer,
      );
    });

    testWidgets(
      'should render the location section with the surface container styling',
      (WidgetTester tester) async {
        await _pumpHomeScreen(tester);

        final ink = tester.widget<Ink>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Ink)),
        );
        final decoration = ink.decoration! as BoxDecoration;

        expect(find.text('LOCATION'), findsOneWidget);
        expect(decoration.color, AppColors.surfaceContainerLow);
      },
    );

    testWidgets('should render the saved location when one is available', (
      WidgetTester tester,
    ) async {
      final fakeLocationService = FakeLocationService(
        loadedLocation: testLocation,
      );

      await _pumpHomeScreen(tester, locationService: fakeLocationService);

      await tester.pumpAndSettle();

      expect(find.text('Northampton, UK'), findsOneWidget);
      expect(find.text('Tap to set your location'), findsNothing);
    });

    testWidgets(
      'should open the location bottom sheet when the location area is tapped',
      (WidgetTester tester) async {
        await _pumpHomeScreen(tester);

        await tester.tap(find.text('Tap to set your location'));
        await tester.pumpAndSettle();

        expect(find.text('Set your location'), findsOneWidget);
        expect(find.text('Use my current location'), findsOneWidget);
        expect(find.text('SEARCH CITY'), findsOneWidget);
      },
    );

    testWidgets(
      'should navigate to settings when the settings icon is tapped',
      (WidgetTester tester) async {
        await _pumpHomeScreen(tester);

        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Settings Destination'), findsOneWidget);
      },
    );

    testWidgets(
      'should update the selected run count when the wheel is scrolled',
      (WidgetTester tester) async {
        final fakeLocationService = FakeLocationService(
          loadedLocation: testLocation,
        );

        await _pumpHomeScreen(tester, locationService: fakeLocationService);
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(ListWheelScrollView),
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();

        final selectedLabel = tester.widget<Text>(
          find.descendant(
            of: find.byType(ListWheelScrollView),
            matching: find.text('5'),
          ),
        );
        expect(
          selectedLabel.style?.color,
          appTheme.colorScheme.onPrimaryContainer,
        );
      },
    );

    testWidgets('should keep the wheel selector visible on a small screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpHomeScreen(tester);

      expect(find.byType(ListWheelScrollView), findsOneWidget);
      expect(find.text('Find my best runs'), findsOneWidget);
    });

    testWidgets('should fetch weather, schedule runs, and navigate to results '
        'when the CTA succeeds', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        loadedLocation: testLocation,
      );
      final fakeWeatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );
      final fakeScheduler = FakeRunScheduler(
        slotsToReturn: <TimeSlot>[
          TimeSlot(
            startTime: DateTime.utc(2026, 3, 16, 9),
            endTime: DateTime.utc(2026, 3, 16, 10),
            score: 0.91,
            temperature: 13,
            precipitationProbability: 5,
            windSpeed: 6,
            weatherCode: 1,
            weatherDescription: 'Clear',
          ),
        ],
      );

      await _pumpHomeScreen(
        tester,
        locationService: fakeLocationService,
        weatherService: fakeWeatherService,
        runScheduler: fakeScheduler,
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Find my best runs'));
      await tester.pumpAndSettle();

      expect(fakeWeatherService.lastCoordinates, (52.2405, -0.9027));
      expect(fakeScheduler.lastNumberOfRuns, 5);
      expect(find.text('Results Destination'), findsOneWidget);
    });

    testWidgets('should show a loading indicator in the CTA when the forecast '
        'request is pending', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        loadedLocation: testLocation,
      );
      final completer = Completer<WeatherResult>();
      final fakeWeatherService = FakeWeatherService(fetchCompleter: completer);
      final fakeScheduler = FakeRunScheduler();

      await _pumpHomeScreen(
        tester,
        locationService: fakeLocationService,
        weatherService: fakeWeatherService,
        runScheduler: fakeScheduler,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Find my best runs'));
      await tester.pump();

      final cta = tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(cta.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(
        WeatherResult(forecast: buildForecastResponse(), isStale: false),
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'should show a snackbar and stay on the home screen when weather '
      'fetching fails',
      (WidgetTester tester) async {
        final fakeLocationService = FakeLocationService(
          loadedLocation: testLocation,
        );
        final fakeWeatherService = FakeWeatherService(
          error: Exception('Weather failed'),
        );

        await _pumpHomeScreen(
          tester,
          locationService: fakeLocationService,
          weatherService: fakeWeatherService,
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Find my best runs'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Weather failed'), findsOneWidget);
        expect(find.text('Results Destination'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Find my best runs'),
              )
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('should show a snackbar and stay on the home screen when '
        'scheduling fails', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        loadedLocation: testLocation,
      );
      final fakeWeatherService = FakeWeatherService(
        weatherResult: WeatherResult(
          forecast: buildForecastResponse(),
          isStale: false,
        ),
      );
      final fakeScheduler = FakeRunScheduler(
        error: Exception('Scheduling failed'),
      );

      await _pumpHomeScreen(
        tester,
        locationService: fakeLocationService,
        weatherService: fakeWeatherService,
        runScheduler: fakeScheduler,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Find my best runs'));
      await tester.pumpAndSettle();

      expect(find.text('Scheduling failed'), findsOneWidget);
      expect(find.text('Results Destination'), findsNothing);
    });
  });

  group('[Widget] LocationBottomSheet', () {
    testWidgets(
      'should validate the manual search input when the query is empty',
      (WidgetTester tester) async {
        await _pumpHomeScreen(tester);

        await tester.tap(find.text('Tap to set your location'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Search'));
        await tester.pump();

        expect(find.text('Enter a city name'), findsOneWidget);
      },
    );

    testWidgets('should search for a location and close the sheet when '
        'manual search succeeds', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        searchLocationResult: testLocation,
      );

      await _pumpHomeScreen(tester, locationService: fakeLocationService);

      await tester.tap(find.text('Tap to set your location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Northampton');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(fakeLocationService.lastSearchQuery, 'Northampton');
      expect(find.text('Set your location'), findsNothing);
      expect(find.text('Northampton, UK'), findsOneWidget);
    });

    testWidgets('should show a manual search error below the search form '
        'when search fails', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        searchLocationError: Exception('Location not found'),
      );

      await _pumpHomeScreen(tester, locationService: fakeLocationService);

      await tester.tap(find.text('Tap to set your location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Atlantis');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(find.text('Location not found'), findsOneWidget);
      expect(find.text('Set your location'), findsOneWidget);
    });

    testWidgets('should detect the current location and close the sheet '
        'when detection succeeds', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        currentLocationResult: testLocation,
      );

      await _pumpHomeScreen(tester, locationService: fakeLocationService);

      await tester.tap(find.text('Tap to set your location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();

      expect(find.text('Set your location'), findsNothing);
      expect(find.text('Northampton, UK'), findsOneWidget);
    });

    testWidgets('should show a current location error below the action '
        'when detection fails', (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService(
        currentLocationError: Exception('GPS unavailable'),
      );

      await _pumpHomeScreen(tester, locationService: fakeLocationService);

      await tester.tap(find.text('Tap to set your location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use my current location'));
      await tester.pumpAndSettle();

      expect(find.text('GPS unavailable'), findsOneWidget);
      expect(find.text('Set your location'), findsOneWidget);
    });
  });
}

Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  FakeLocationService? locationService,
  FakeWeatherService? weatherService,
  FakeRunScheduler? runScheduler,
}) async {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: Center(child: Text('Settings Destination')),
          );
        },
      ),
      GoRoute(
        path: '/results',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: Center(child: Text('Results Destination')),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        if (locationService != null)
          locationServiceProvider.overrideWithValue(locationService),
        if (weatherService != null)
          weatherServiceProvider.overrideWithValue(weatherService),
        if (runScheduler != null)
          runSchedulerServiceProvider.overrideWithValue(runScheduler),
        sharedPreferencesLoaderProvider.overrideWithValue(
          SharedPreferences.getInstance,
        ),
      ],
      child: MaterialApp.router(theme: appTheme, routerConfig: router),
    ),
  );

  await tester.pump();
}

class FakeLocationService extends LocationService {
  FakeLocationService({
    this.loadedLocation,
    this.currentLocationResult,
    this.searchLocationResult,
    this.loadError,
    this.currentLocationError,
    this.searchLocationError,
  }) : super();

  final LocationData? loadedLocation;
  final LocationData? currentLocationResult;
  final LocationData? searchLocationResult;
  final Exception? loadError;
  final Exception? currentLocationError;
  final Exception? searchLocationError;

  String? lastSearchQuery;

  @override
  Future<LocationData?> loadLastLocation() async {
    if (loadError != null) {
      throw loadError!;
    }

    return loadedLocation;
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    if (currentLocationError != null) {
      throw currentLocationError!;
    }

    return currentLocationResult!;
  }

  @override
  Future<LocationData> searchLocation(String query) async {
    lastSearchQuery = query;
    if (searchLocationError != null) {
      throw searchLocationError!;
    }

    return searchLocationResult!;
  }

  @override
  Future<void> saveLastLocation(LocationData location) async {}
}

class FakeWeatherService extends WeatherService {
  FakeWeatherService({this.weatherResult, this.error, this.fetchCompleter})
    : super();

  final WeatherResult? weatherResult;
  final Exception? error;
  final Completer<WeatherResult>? fetchCompleter;

  (double, double)? lastCoordinates;

  @override
  Future<WeatherResult> fetchHourlyForecast(double lat, double lng) async {
    lastCoordinates = (lat, lng);

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

  int? lastNumberOfRuns;

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
    lastNumberOfRuns = numberOfRuns;

    if (error != null) {
      throw error!;
    }

    return slotsToReturn;
  }
}

const testLocation = LocationData(
  latitude: 52.2405,
  longitude: -0.9027,
  displayName: 'Northampton, UK',
);

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
