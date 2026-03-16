import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/forecast_response.dart';
import 'package:run_check/models/hourly_forecast.dart';
import 'package:run_check/models/sunrise_sunset.dart';
import 'package:run_check/models/weather_state.dart';

void main() {
  group('[Unit] WeatherState', () {
    test(
      'should default to an idle non-stale empty state when constructed',
      () {
        const state = WeatherState();

        expect(state.forecast, isNull);
        expect(state.isStale, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );

    test(
      'should replace the forecast and clear the error when copyWith is used',
      () {
        final forecast = ForecastResponse(
          latitude: 51.5072,
          longitude: -0.1276,
          timezone: 'Europe/London',
          hourlyForecasts: [
            HourlyForecast(
              dateTime: DateTime.utc(2026, 3, 16, 9),
              temperature: 14,
              precipitationProbability: 10,
              windSpeed: 8,
              humidity: 55,
              weatherCode: 1,
            ),
          ],
          dailySunData: [
            SunriseSunset(
              date: DateTime.utc(2026, 3, 16),
              sunrise: DateTime.utc(2026, 3, 16, 6, 20),
              sunset: DateTime.utc(2026, 3, 16, 18, 10),
            ),
          ],
        );
        const initialState = WeatherState(
          isStale: true,
          isLoading: true,
          errorMessage: 'Old error',
        );

        final nextState = initialState.copyWith(
          forecast: forecast,
          isStale: false,
          isLoading: false,
          errorMessage: null,
        );

        expect(nextState.forecast, same(forecast));
        expect(nextState.isStale, isFalse);
        expect(nextState.isLoading, isFalse);
        expect(nextState.errorMessage, isNull);
      },
    );
  });
}
