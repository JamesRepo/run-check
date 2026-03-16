import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/providers/settings_provider.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: <Widget>[
          _SectionHeader(title: 'Preferences', theme: theme),
          Card(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Temperature Unit',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<TemperatureUnit>(
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
                        onSelectionChanged: (Set<TemperatureUnit> selection) {
                          final unit = selection.first;
                          settingsNotifier.setUnit(unit);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Preferred time of day',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select when you usually like to train.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timePeriodOptions
                            .map((option) {
                              final isSelected = settings.preferredPeriods
                                  .contains(option.value);

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
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Typical Run Duration',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<int>(
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
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Cyclist Mode'),
                  subtitle: const Text(
                    'Increases wind sensitivity for cycling',
                  ),
                  value: settings.cyclistMode,
                  onChanged: (bool value) {
                    settingsNotifier.setCyclistMode(cyclistMode: value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'About', theme: theme),
          Card(
            child: Column(
              children: <Widget>[
                const ListTile(
                  title: Text('App Version'),
                  subtitle: Text('Version $_appVersion'),
                  trailing: Icon(Icons.info_outline),
                  // TODO(james): Read this from package_info_plus if version
                  // metadata needs to stay in sync automatically.
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new),
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
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
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
