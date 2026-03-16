import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/services/location_service.dart';
import 'package:run_check/services/run_scheduler.dart';
import 'package:run_check/services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final runSchedulerServiceProvider = Provider<RunScheduler>((ref) {
  return const RunScheduler();
});
