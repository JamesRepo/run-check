import 'package:flutter/material.dart';
import 'package:run_check/utils/app_colors.dart';

class RunCountSelector extends StatelessWidget {
  const RunCountSelector({
    required this.selectedCount,
    required this.onSelected,
    super.key,
  });

  final int selectedCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final outerSize = ((screenWidth - 40) / 7).clamp(40.0, 48.0);
    final innerSize = (outerSize - 4).clamp(36.0, 44.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(7, (int index) {
        final value = index + 1;
        final isSelected = value == selectedCount;

        return SizedBox(
          width: outerSize,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(value),
              customBorder: const CircleBorder(),
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.1 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
