import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_shadows.dart';
import 'package:run_check/utils/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _timePeriodOptions = <_TimePeriodOption>[
    _TimePeriodOption(value: 'morning', label: 'Morning'),
    _TimePeriodOption(value: 'afternoon', label: 'Afternoon'),
    _TimePeriodOption(value: 'evening', label: 'Evening'),
  ];

  static const _runDurationOptions = UserPreferences.supportedRunDurations;
  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: colorScheme.primaryContainer),
          tooltip: 'Back',
        ),
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          32,
          AppSpacing.screenPaddingH,
          AppSpacing.cardGap,
        ),
        children: <Widget>[
          const _SectionHeader(title: 'Preferences'),
          const SizedBox(height: 16),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Temperature unit',
                  style: _settingLabelStyle(theme, colorScheme),
                ),
                const SizedBox(height: 16),
                _SegmentedControl<TemperatureUnit>(
                  value: settings.unit,
                  options: const <_SegmentedOption<TemperatureUnit>>[
                    _SegmentedOption(
                      value: TemperatureUnit.celsius,
                      label: '°C',
                    ),
                    _SegmentedOption(
                      value: TemperatureUnit.fahrenheit,
                      label: '°F',
                    ),
                  ],
                  onSelected: settingsNotifier.setUnit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Preferred time of day',
                  style: _settingLabelStyle(theme, colorScheme),
                ),
                const SizedBox(height: AppSpacing.labelToContentGap),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _timePeriodOptions
                      .map((option) {
                        final isSelected = settings.preferredPeriods.contains(
                          option.value,
                        );

                        return _SelectableChip(
                          label: option.label,
                          selected: isSelected,
                          onSelected: (bool selected) {
                            _handlePreferredPeriodToggle(
                              context: context,
                              ref: ref,
                              period: option.value,
                              selected: selected,
                            );
                          },
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Run duration goal',
                  style: _settingLabelStyle(theme, colorScheme),
                ),
                const SizedBox(height: AppSpacing.labelToContentGap),
                _SegmentedControl<int>(
                  value: settings.runDurationMinutes,
                  outerRadius: 12,
                  innerRadius: 8,
                  shadowColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  options: _runDurationOptions
                      .map(
                        (int minutes) => _SegmentedOption<int>(
                          value: minutes,
                          label: '$minutes min',
                        ),
                      )
                      .toList(growable: false),
                  onSelected: settingsNotifier.setRunDuration,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            backgroundColor: AppColors.surfaceContainerLowest,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Cyclist mode',
                        style: _settingLabelStyle(theme, colorScheme),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Increases wind sensitivity',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.cyclistMode,
                  onChanged: (bool value) {
                    settingsNotifier.setCyclistMode(cyclistMode: value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _SectionHeader(title: 'About'),
          const SizedBox(height: 16),
          _SettingsGroup(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('App Version', style: theme.textTheme.titleLarge),
                  subtitle: Text(
                    'Version $_appVersion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  // TODO(james): Read this from package_info_plus if version
                  // metadata needs to stay in sync automatically.
                ),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Privacy Policy',
                    style: theme.textTheme.titleLarge,
                  ),
                  trailing: Icon(Icons.open_in_new, color: colorScheme.primary),
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Privacy policy coming soon'),
                        ),
                      );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePreferredPeriodToggle({
    required BuildContext context,
    required WidgetRef ref,
    required String period,
    required bool selected,
  }) {
    final settings = ref.read(settingsProvider);
    final currentPeriods = settings.preferredPeriods;

    final nextPeriods = selected
        ? <String>[...currentPeriods, period]
        : currentPeriods.where((String value) => value != period).toList();

    if (nextPeriods.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('At least one time period must be selected'),
          ),
        );
      return;
    }

    ref.read(settingsProvider.notifier).setPreferredPeriods(nextPeriods);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.8),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.child,
    this.backgroundColor = AppColors.surfaceContainerLow,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.settingsGroupPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.settingsGroup),
      ),
      child: child,
    );
  }
}

TextStyle? _settingLabelStyle(ThemeData theme, ColorScheme colorScheme) {
  return theme.textTheme.bodyMedium?.copyWith(
    color: colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w500,
  );
}

class _SegmentedControl<T> extends StatelessWidget {
  const _SegmentedControl({
    required this.value,
    required this.options,
    required this.onSelected,
    this.outerRadius = AppRadii.button,
    this.innerRadius = AppRadii.button,
    this.shadowColor,
  });

  final T value;
  final List<_SegmentedOption<T>> options;
  final ValueChanged<T> onSelected;
  final double outerRadius;
  final double innerRadius;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: Row(
        children: options
            .map(
              (_SegmentedOption<T> option) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _SegmentButton<T>(
                    option: option,
                    selected: option.value == value,
                    onPressed: onSelected,
                    radius: innerRadius,
                    shadowColor: shadowColor,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onPressed,
    required this.radius,
    this.shadowColor,
  });

  final _SegmentedOption<T> option;
  final bool selected;
  final ValueChanged<T> onPressed;
  final double radius;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () => onPressed(option.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: selected && shadowColor != null
                ? <BoxShadow>[
                    AppShadows.editorialShadow.copyWith(color: shadowColor),
                  ]
                : const <BoxShadow>[],
          ),
          alignment: Alignment.center,
          child: Text(
            option.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : AppColors.onSecondaryContainerMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected ? colorScheme.primary : AppColors.secondaryFixed,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        onTap: () => onSelected(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            boxShadow: selected
                ? <BoxShadow>[
                    AppShadows.editorialShadow.copyWith(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : AppColors.onSecondaryFixed,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedOption<T> {
  const _SegmentedOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _TimePeriodOption {
  const _TimePeriodOption({required this.value, required this.label});

  final String value;
  final String label;
}
