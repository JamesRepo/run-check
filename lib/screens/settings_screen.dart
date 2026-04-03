import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _timePeriodOptions = <_TimePeriodOption>[
    _TimePeriodOption(
      value: 'morning',
      label: 'Morning',
      description: '5am-12pm',
    ),
    _TimePeriodOption(
      value: 'afternoon',
      label: 'Afternoon',
      description: '12pm-6pm',
    ),
    _TimePeriodOption(
      value: 'evening',
      label: 'Evening',
      description: '6pm-9pm',
    ),
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
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingTop,
          AppSpacing.screenPaddingH,
          AppSpacing.cardGap,
        ),
        children: <Widget>[
          const _SectionHeader(title: 'Preferences'),
          const SizedBox(height: AppSpacing.labelToContentGap),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Temperature Unit', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.labelToContentGap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.settingsGroup),
                  child: SegmentedButton<TemperatureUnit>(
                    segments: const <ButtonSegment<TemperatureUnit>>[
                      ButtonSegment<TemperatureUnit>(
                        value: TemperatureUnit.celsius,
                        label: Text('°C'),
                      ),
                      ButtonSegment<TemperatureUnit>(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('°F'),
                      ),
                    ],
                    selected: <TemperatureUnit>{settings.unit},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<TemperatureUnit> selection) {
                      final unit = selection.first;
                      settingsNotifier.setUnit(unit);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Preferred time of day',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.chipGap),
                Text(
                  'Select when you usually like to train.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.labelToContentGap),
                Wrap(
                  spacing: AppSpacing.chipGap,
                  runSpacing: AppSpacing.chipGap,
                  children: _timePeriodOptions
                      .map((option) {
                        final isSelected = settings.preferredPeriods.contains(
                          option.value,
                        );

                        return FilterChip(
                          label: Text(
                            '${option.label} (${option.description})',
                          ),
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
          const SizedBox(height: AppSpacing.cardGap),
          _SettingsGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Typical Run Duration', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.labelToContentGap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.settingsGroup),
                  child: SegmentedButton<int>(
                    segments: _runDurationOptions
                        .map(
                          (int minutes) => ButtonSegment<int>(
                            value: minutes,
                            label: Text('$minutes min'),
                          ),
                        )
                        .toList(growable: false),
                    selected: <int>{settings.runDurationMinutes},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<int> selection) {
                      final duration = selection.first;
                      settingsNotifier.setRunDuration(duration);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          _SettingsGroup(
            backgroundColor: AppColors.surfaceContainerLowest,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Cyclist Mode', style: theme.textTheme.titleLarge),
              subtitle: Text(
                'Increases wind sensitivity for cycling',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: settings.cyclistMode,
              onChanged: (bool value) {
                settingsNotifier.setCyclistMode(cyclistMode: value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const _SectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.labelToContentGap),
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

class _TimePeriodOption {
  const _TimePeriodOption({
    required this.value,
    required this.label,
    required this.description,
  });

  final String value;
  final String label;
  final String description;
}
