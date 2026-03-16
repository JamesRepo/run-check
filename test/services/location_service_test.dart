import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:run_check/models/location_data.dart';
import 'package:run_check/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  group('[Unit] LocationService', () {
    test('should expose recoverable location failures as Exception types', () {
      expect(LocationServiceDisabledException(), isA<Exception>());
      expect(LocationServiceDisabledException(), isNot(isA<Error>()));
      expect(LocationPermissionDeniedException(), isA<Exception>());
      expect(LocationPermissionDeniedException(), isNot(isA<Error>()));
      expect(LocationPermissionPermanentlyDeniedException(), isA<Exception>());
      expect(
        LocationPermissionPermanentlyDeniedException(),
        isNot(isA<Error>()),
      );
      expect(LocationNotFoundException('query'), isA<Exception>());
      expect(LocationNotFoundException('query'), isNot(isA<Error>()));
    });

    test('should throw LocationServiceDisabledException '
        'when services are disabled', () async {
      final geolocator = FakeGeolocatorPlatform(serviceEnabled: false);
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.getCurrentLocation(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      expect(geolocator.requestPermissionCallCount, 0);
      expect(geolocator.getCurrentPositionCallCount, 0);
    });

    test('should throw LocationPermissionDeniedException '
        'when permission remains denied', () async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.denied,
        requestedPermissionResult: LocationPermission.denied,
      );
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
      expect(geolocator.requestPermissionCallCount, 1);
      expect(geolocator.getCurrentPositionCallCount, 0);
    });

    test('should throw LocationPermissionPermanentlyDeniedException '
        'when permission is denied forever before requesting', () async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.deniedForever,
      );
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.getCurrentLocation(),
        throwsA(isA<LocationPermissionPermanentlyDeniedException>()),
      );
      expect(geolocator.requestPermissionCallCount, 0);
      expect(geolocator.getCurrentPositionCallCount, 0);
    });

    test('should throw LocationPermissionPermanentlyDeniedException '
        'when permission changes to denied forever after requesting', () async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.denied,
        requestedPermissionResult: LocationPermission.deniedForever,
      );
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.getCurrentLocation(),
        throwsA(isA<LocationPermissionPermanentlyDeniedException>()),
      );
      expect(geolocator.requestPermissionCallCount, 1);
      expect(geolocator.getCurrentPositionCallCount, 0);
    });

    test('should return the current location with a placemark display name '
        'when permission is granted', () async {
      final geolocator = FakeGeolocatorPlatform(position: _position());
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
        placemarksResult: const [
          Placemark(locality: 'Northampton', country: 'UK'),
        ],
      );

      final location = await service.getCurrentLocation();

      expect(location.latitude, 52.2405);
      expect(location.longitude, -0.9027);
      expect(location.displayName, 'Northampton, UK');
      expect(service.lastPlacemarkLookup, (52.2405, -0.9027));
    });

    test('should use fallback placemark fields '
        'when primary locality fields are empty', () async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.always,
        position: _position(latitude: 40.7128, longitude: -74.006),
      );
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
        placemarksResult: const [
          Placemark(administrativeArea: 'New York', isoCountryCode: 'US'),
        ],
      );

      final location = await service.getCurrentLocation();

      expect(location.displayName, 'New York, US');
    });

    test('should fall back to formatted coordinates '
        'when reverse geocoding returns no placemarks', () async {
      final geolocator = FakeGeolocatorPlatform(
        position: _position(latitude: 51.507351, longitude: -0.127758),
      );
      final service = TestLocationService(
        geolocatorPlatform: geolocator,
        sharedPreferences: sharedPreferences,
      );

      final location = await service.getCurrentLocation();

      expect(location.displayName, '51.5074, -0.1278');
    });

    test('should return searched coordinates with a clean display name '
        'when geocoding succeeds', () async {
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
        locationsResult: [
          Location(
            latitude: 52.2405,
            longitude: -0.9027,
            timestamp: _timestamp,
          ),
        ],
        placemarksResult: const [
          Placemark(subAdministrativeArea: 'Northampton', country: 'UK'),
        ],
      );

      final location = await service.searchLocation('  Northampton  ');

      expect(location, isA<LocationData>());
      expect(location.latitude, 52.2405);
      expect(location.longitude, -0.9027);
      expect(location.displayName, 'Northampton, UK');
      expect(service.lastSearchQuery, 'Northampton');
    });

    test('should throw LocationNotFoundException '
        'when the search query is empty after trimming', () async {
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.searchLocation('   '),
        throwsA(
          isA<LocationNotFoundException>().having(
            (exception) => exception.query,
            'query',
            '',
          ),
        ),
      );
      expect(service.lastSearchQuery, isNull);
    });

    test('should throw LocationNotFoundException '
        'when no geocoding results are returned', () async {
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
      );

      await expectLater(
        service.searchLocation('Atlantis'),
        throwsA(
          isA<LocationNotFoundException>().having(
            (exception) => exception.query,
            'query',
            'Atlantis',
          ),
        ),
      );
    });

    test('should save the last location as json when requested', () async {
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
      );
      const location = LocationData(
        latitude: 52.2405,
        longitude: -0.9027,
        displayName: 'Northampton, UK',
      );

      await service.saveLastLocation(location);

      final rawValue = sharedPreferences.getString('last_location');
      expect(rawValue, isNotNull);
      expect(jsonDecode(rawValue!), {
        'latitude': 52.2405,
        'longitude': -0.9027,
        'displayName': 'Northampton, UK',
      });
    });

    test('should remove the saved last location when clearing', () async {
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
      );
      await sharedPreferences.setString(
        'last_location',
        jsonEncode({
          'latitude': 52.2405,
          'longitude': -0.9027,
          'displayName': 'Northampton, UK',
        }),
      );

      await service.clearLastLocation();

      expect(sharedPreferences.getString('last_location'), isNull);
    });

    test(
      'should return null when loading the last location and nothing is saved',
      () async {
        final service = TestLocationService(
          geolocatorPlatform: FakeGeolocatorPlatform(),
          sharedPreferences: sharedPreferences,
        );

        final location = await service.loadLastLocation();

        expect(location, isNull);
      },
    );

    test(
      'should deserialize the last location when a saved json string exists',
      () async {
        await sharedPreferences.setString(
          'last_location',
          jsonEncode({
            'latitude': 52.2405,
            'longitude': -0.9027,
            'displayName': 'Northampton, UK',
          }),
        );
        final service = TestLocationService(
          geolocatorPlatform: FakeGeolocatorPlatform(),
          sharedPreferences: sharedPreferences,
        );

        final location = await service.loadLastLocation();

        expect(location, isNotNull);
        expect(location!.latitude, 52.2405);
        expect(location.longitude, -0.9027);
        expect(location.displayName, 'Northampton, UK');
      },
    );

    test('should return null when loading the last location '
        'and the saved json is invalid', () async {
      await sharedPreferences.setString('last_location', '{bad json');
      final service = TestLocationService(
        geolocatorPlatform: FakeGeolocatorPlatform(),
        sharedPreferences: sharedPreferences,
      );

      final location = await service.loadLastLocation();

      expect(location, isNull);
    });
  });
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    LocationPermission? requestedPermissionResult,
    Position? position,
  }) : requestedPermissionResult = requestedPermissionResult ?? permission,
       position = position ?? _position();

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission requestedPermissionResult;
  final Position position;

  int requestPermissionCallCount = 0;
  int getCurrentPositionCallCount = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    getCurrentPositionCallCount++;
    return position;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount++;
    return requestedPermissionResult;
  }
}

class TestLocationService extends LocationService {
  TestLocationService({
    required super.geolocatorPlatform,
    required super.sharedPreferences,
    this.locationsResult = const [],
    this.placemarksResult = const [],
  });

  final List<Location> locationsResult;
  final List<Placemark> placemarksResult;

  String? lastSearchQuery;
  (double, double)? lastPlacemarkLookup;

  @override
  Future<List<Location>> locationsFromAddress(String query) async {
    lastSearchQuery = query;
    return locationsResult;
  }

  @override
  Future<List<Placemark>> placemarksFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    lastPlacemarkLookup = (latitude, longitude);
    return placemarksResult;
  }
}

final _timestamp = DateTime.utc(2026, 3, 16, 9);

Position _position({double latitude = 52.2405, double longitude = -0.9027}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: _timestamp,
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}
