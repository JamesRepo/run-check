import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/theme.dart';
import 'package:run_check/widgets/run_count_selector.dart';

void main() {
  group('[Widget] RunCountSelector', () {
    testWidgets('should render seven chip values when built', (
      WidgetTester tester,
    ) async {
      await _pumpSelector(tester, selectedCount: 3);

      for (var value = 1; value <= 7; value++) {
        expect(find.text('$value'), findsOneWidget);
      }
    });

    testWidgets('should highlight the selected chip when a selected count is '
        'provided', (WidgetTester tester) async {
      await _pumpSelector(tester, selectedCount: 4);

      final selectedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('4'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final selectedScale = tester.widget<AnimatedScale>(
        find.ancestor(of: find.text('4'), matching: find.byType(AnimatedScale)),
      );
      final unselectedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.text('2'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final selectedDecoration = selectedContainer.decoration! as BoxDecoration;
      final unselectedDecoration =
          unselectedContainer.decoration! as BoxDecoration;

      expect(selectedDecoration.color, appTheme.colorScheme.primaryContainer);
      expect(selectedDecoration.boxShadow, isNotEmpty);
      expect(selectedScale.scale, 1.1);
      expect(unselectedDecoration.color, AppColors.surfaceContainerLowest);
      expect(unselectedDecoration.boxShadow, isNull);
    });

    testWidgets('should call onSelected with the tapped value when a chip is '
        'pressed', (WidgetTester tester) async {
      int? selectedValue;

      await _pumpSelector(
        tester,
        selectedCount: 3,
        onSelected: (int value) {
          selectedValue = value;
        },
      );

      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(selectedValue, 6);
    });
  });
}

Future<void> _pumpSelector(
  WidgetTester tester, {
  required int selectedCount,
  ValueChanged<int>? onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: Center(
          child: RunCountSelector(
            selectedCount: selectedCount,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}
