import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/models/location_data.dart';
import 'package:run_check/models/weather_state.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/services/weather_service.dart';

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((
  ref,
) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService: weatherService);
});

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier({required WeatherService weatherService})
    : _weatherService = weatherService,
      super(const WeatherState());

  final WeatherService _weatherService;

  Future<void> fetchForecast(LocationData location) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _weatherService.fetchHourlyForecast(
        location.latitude,
        location.longitude,
      );

      state = state.copyWith(
        forecast: result.forecast,
        isStale: result.isStale,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  String _formatError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
