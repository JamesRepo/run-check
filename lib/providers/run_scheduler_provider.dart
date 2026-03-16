import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/models/schedule_state.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/providers/service_providers.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/services/run_scheduler.dart';

final runSchedulerProvider =
    StateNotifierProvider<RunSchedulerNotifier, ScheduleState>((ref) {
      final runScheduler = ref.watch(runSchedulerServiceProvider);
      return RunSchedulerNotifier(ref: ref, runScheduler: runScheduler);
    });

class RunSchedulerNotifier extends StateNotifier<ScheduleState> {
  RunSchedulerNotifier({required Ref ref, required RunScheduler runScheduler})
    : _ref = ref,
      _runScheduler = runScheduler,
      super(ScheduleState());

  final Ref _ref;
  final RunScheduler _runScheduler;

  Future<void> findSlots({required int numberOfRuns}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      requestedRuns: numberOfRuns,
    );

    try {
      final weatherState = _ref.read(weatherProvider);
      final forecast = weatherState.forecast;
      if (forecast == null) {
        state = state.copyWith(
          slots: const <TimeSlot>[],
          isLoading: false,
          errorMessage: 'No forecast available for scheduling.',
        );
        return;
      }

      final preferences = _ref.read(settingsProvider);
      final slots = _runScheduler.findBestSlots(
        forecasts: forecast.hourlyForecasts,
        numberOfRuns: numberOfRuns,
        runDurationMinutes: preferences.runDurationMinutes,
        preferredPeriods: preferences.preferredPeriods,
        sunData: forecast.dailySunData,
      );

      state = state.copyWith(
        slots: slots,
        isLoading: false,
        errorMessage: null,
      );
    } on Object catch (error) {
      state = state.copyWith(
        slots: const <TimeSlot>[],
        isLoading: false,
        errorMessage: _formatError(error),
      );
    }
  }

  String _formatError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
