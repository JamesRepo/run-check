import 'package:flutter/material.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_spacing.dart';

class RunCountSelector extends StatefulWidget {
  const RunCountSelector({
    required this.selectedCount,
    required this.onSelected,
    super.key,
  });

  final int selectedCount;
  final ValueChanged<int> onSelected;

  @override
  State<RunCountSelector> createState() => _RunCountSelectorState();
}

class _RunCountSelectorState extends State<RunCountSelector> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedCount - 1,
    );
  }

  @override
  void didUpdateWidget(covariant RunCountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCount != widget.selectedCount) {
      _controller.jumpToItem(widget.selectedCount - 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.dataPillPaddingH,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.dataPill),
                  ),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 40,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (int index) => widget.onSelected(index + 1),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 7,
              builder: (BuildContext context, int index) {
                if (index < 0 || index > 6) {
                  return null;
                }

                final value = index + 1;
                final isSelected = value == widget.selectedCount;

                return Center(
                  child: Text(
                    '$value',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
