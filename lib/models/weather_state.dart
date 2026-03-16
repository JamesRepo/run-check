import 'package:run_check/models/forecast_response.dart';

class WeatherState {
  const WeatherState({
    this.forecast,
    this.isStale = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final ForecastResponse? forecast;
  final bool isStale;
  final bool isLoading;
  final String? errorMessage;

  static const _sentinel = Object();

  WeatherState copyWith({
    Object? forecast = _sentinel,
    bool? isStale,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return WeatherState(
      forecast: identical(forecast, _sentinel)
          ? this.forecast
          : forecast as ForecastResponse?,
      isStale: isStale ?? this.isStale,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
