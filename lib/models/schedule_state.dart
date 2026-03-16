import 'package:run_check/models/time_slot.dart';

class ScheduleState {
  ScheduleState({
    List<TimeSlot> slots = const <TimeSlot>[],
    this.isLoading = false,
    this.errorMessage,
    this.requestedRuns = 0,
  }) : slots = List<TimeSlot>.unmodifiable(slots);

  final List<TimeSlot> slots;
  final bool isLoading;
  final String? errorMessage;
  final int requestedRuns;

  static const _sentinel = Object();

  ScheduleState copyWith({
    Object? slots = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    int? requestedRuns,
  }) {
    return ScheduleState(
      slots: identical(slots, _sentinel)
          ? this.slots
          : List<TimeSlot>.unmodifiable(slots! as List<TimeSlot>),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      requestedRuns: requestedRuns ?? this.requestedRuns,
    );
  }
}
