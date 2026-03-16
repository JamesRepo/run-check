import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/models/schedule_state.dart';
import 'package:run_check/models/time_slot.dart';

void main() {
  group('[Unit] ScheduleState', () {
    test('should default to an idle state with no requested runs', () {
      final state = ScheduleState();

      expect(state.slots, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.requestedRuns, 0);
    });

    test('should store an unmodifiable slots list when copyWith is used', () {
      final slot = TimeSlot(
        startTime: DateTime.utc(2026, 3, 16, 9),
        endTime: DateTime.utc(2026, 3, 16, 10),
        score: 0.91,
        temperature: 14,
        precipitationProbability: 10,
        windSpeed: 8,
        weatherCode: 1,
        weatherDescription: 'Mainly clear',
      );

      final nextState = ScheduleState().copyWith(
        slots: <TimeSlot>[slot],
        requestedRuns: 2,
      );

      expect(nextState.slots, hasLength(1));
      expect(nextState.slots.single, same(slot));
      expect(nextState.requestedRuns, 2);
      expect(() => nextState.slots.add(slot), throwsUnsupportedError);
    });

    test(
      'should store an unmodifiable slots list when constructed directly',
      () {
        final slot = TimeSlot(
          startTime: DateTime.utc(2026, 3, 16, 9),
          endTime: DateTime.utc(2026, 3, 16, 10),
          score: 0.91,
          temperature: 14,
          precipitationProbability: 10,
          windSpeed: 8,
          weatherCode: 1,
          weatherDescription: 'Mainly clear',
        );
        final originalSlots = <TimeSlot>[slot];
        final state = ScheduleState(slots: originalSlots);

        originalSlots.add(slot);

        expect(state.slots, hasLength(1));
        expect(() => state.slots.add(slot), throwsUnsupportedError);
      },
    );
  });
}
