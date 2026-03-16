import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/services/location_service.dart';

void main() {
  group('[Unit] LocationProvider', () {
    test(
      'should load the saved location when the provider initializes',
      () async {
        final fakeService = FakeLocationService(
          loadedLocation: const LocationData(
            latitude: 51.5072,
            longitude: -0.1276,
            displayName: 'London, UK',
          ),
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(locationProvider);
        await flushAsyncWork();

        final state = container.read(locationProvider);
        expect(state.location?.displayName, 'London, UK');
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );

    test(
      'should update state and persist the result when detecting location',
      () async {
        const detectedLocation = LocationData(
          latitude: 52.2405,
          longitude: -0.9027,
          displayName: 'Northampton, UK',
        );
        final fakeService = FakeLocationService(
          currentLocationResult: detectedLocation,
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        await container.read(locationProvider.notifier).detectCurrentLocation();

        final state = container.read(locationProvider);
        expect(state.location, same(detectedLocation));
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
        expect(fakeService.savedLocations, [detectedLocation]);
      },
    );

    test(
      'should update state and persist the result when searching location',
      () async {
        const searchedLocation = LocationData(
          latitude: 40.7128,
          longitude: -74.006,
          displayName: 'New York, US',
        );
        final fakeService = FakeLocationService(
          searchLocationResult: searchedLocation,
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        await container
            .read(locationProvider.notifier)
            .searchLocation('New York');

        final state = container.read(locationProvider);
        expect(state.location, same(searchedLocation));
        expect(state.errorMessage, isNull);
        expect(fakeService.lastSearchQuery, 'New York');
        expect(fakeService.savedLocations, [searchedLocation]);
      },
    );

    test('should expose an error message when detection fails', () async {
      final fakeService = FakeLocationService(
        currentLocationError: Exception('GPS unavailable'),
      );
      final container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      await container.read(locationProvider.notifier).detectCurrentLocation();

      final state = container.read(locationProvider);
      expect(state.location, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'GPS unavailable');
    });

    test(
      'should keep the detected location when saved hydration finishes later',
      () async {
        const savedLocation = LocationData(
          latitude: 51.5072,
          longitude: -0.1276,
          displayName: 'London, UK',
        );
        const detectedLocation = LocationData(
          latitude: 52.2405,
          longitude: -0.9027,
          displayName: 'Northampton, UK',
        );
        final loadCompleter = Completer<LocationData?>();
        final fakeService = FakeLocationService(
          currentLocationResult: detectedLocation,
          loadLocationFuture: loadCompleter.future,
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(locationProvider);
        await container.read(locationProvider.notifier).detectCurrentLocation();
        loadCompleter.complete(savedLocation);
        await flushAsyncWork();

        final state = container.read(locationProvider);
        expect(state.location, detectedLocation);
        expect(state.errorMessage, isNull);
      },
    );

    test(
      'should keep the cleared state when saved hydration finishes later',
      () async {
        const savedLocation = LocationData(
          latitude: 51.5072,
          longitude: -0.1276,
          displayName: 'London, UK',
        );
        final loadCompleter = Completer<LocationData?>();
        final fakeService = FakeLocationService(
          loadLocationFuture: loadCompleter.future,
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(locationProvider);
        await container.read(locationProvider.notifier).clearLocation();
        loadCompleter.complete(savedLocation);
        await flushAsyncWork();

        final state = container.read(locationProvider);
        expect(state.location, isNull);
        expect(state.errorMessage, isNull);
      },
    );

    test(
      'should clear the current state and persisted location when requested',
      () async {
        final fakeService = FakeLocationService(
          loadedLocation: const LocationData(
            latitude: 51.5072,
            longitude: -0.1276,
            displayName: 'London, UK',
          ),
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(locationProvider);
        await flushAsyncWork();
        await container.read(locationProvider.notifier).clearLocation();

        final state = container.read(locationProvider);
        expect(state.location, isNull);
        expect(state.errorMessage, isNull);
        expect(fakeService.clearCallCount, 1);
      },
    );

    test(
      'should expose an error message when loading the saved location fails',
      () async {
        final fakeService = FakeLocationService(
          loadError: Exception('Bad cache'),
        );
        final container = ProviderContainer(
          overrides: [locationServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        container.read(locationProvider);
        await flushAsyncWork();

        final state = container.read(locationProvider);
        expect(state.location, isNull);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, 'Bad cache');
      },
    );
  });

  group('[Widget] LocationProvider', () {
    testWidgets(
      'should rebuild the widget when detecting a location succeeds',
      (tester) async {
        final fakeService = FakeLocationService(
          currentLocationResult: const LocationData(
            latitude: 52.2405,
            longitude: -0.9027,
            displayName: 'Northampton, UK',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [locationServiceProvider.overrideWithValue(fakeService)],
            child: const MaterialApp(home: _LocationConsumerWidget()),
          ),
        );

        expect(find.text('none'), findsOneWidget);

        await tester.tap(find.text('Detect'));
        await tester.pumpAndSettle();

        expect(find.text('Northampton, UK'), findsOneWidget);
      },
    );
  });
}

class FakeLocationService extends LocationService {
  FakeLocationService({
    this.loadedLocation,
    this.loadLocationFuture,
    this.currentLocationResult,
    this.searchLocationResult,
    this.loadError,
    this.currentLocationError,
    this.searchLocationError,
    this.clearError,
  }) : super();

  final LocationData? loadedLocation;
  final Future<LocationData?>? loadLocationFuture;
  final LocationData? currentLocationResult;
  final LocationData? searchLocationResult;
  final Exception? loadError;
  final Exception? currentLocationError;
  final Exception? searchLocationError;
  final Exception? clearError;

  final List<LocationData> savedLocations = <LocationData>[];
  String? lastSearchQuery;
  int clearCallCount = 0;

  @override
  Future<void> clearLastLocation() async {
    clearCallCount++;
    if (clearError != null) {
      throw clearError!;
    }
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    if (currentLocationError != null) {
      throw currentLocationError!;
    }

    return currentLocationResult!;
  }

  @override
  Future<LocationData?> loadLastLocation() async {
    if (loadError != null) {
      throw loadError!;
    }

    if (loadLocationFuture != null) {
      return loadLocationFuture!;
    }

    return loadedLocation;
  }

  @override
  Future<void> saveLastLocation(LocationData location) async {
    savedLocations.add(location);
  }

  @override
  Future<LocationData> searchLocation(String query) async {
    lastSearchQuery = query;
    if (searchLocationError != null) {
      throw searchLocationError!;
    }

    return searchLocationResult!;
  }
}

class _LocationConsumerWidget extends ConsumerWidget {
  const _LocationConsumerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationProvider);

    return Scaffold(
      body: Column(
        children: [
          Text(state.location?.displayName ?? 'none'),
          ElevatedButton(
            onPressed: () {
              ref.read(locationProvider.notifier).detectCurrentLocation();
            },
            child: const Text('Detect'),
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
