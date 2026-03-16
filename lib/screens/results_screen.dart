import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/widgets/time_slot_card.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleState = ref.watch(runSchedulerProvider);
    final weatherState = ref.watch(weatherProvider);
    final settings = ref.watch(settingsProvider);

    final slots = scheduleState.slots;
    final requestedRuns = scheduleState.requestedRuns;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Your Best Runs'),
        actions: <Widget>[
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: slots.isEmpty
          ? _buildEmptyState(theme, colorScheme)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: <Widget>[
                  if (weatherState.isStale)
                    _StaleBanner(colorScheme: colorScheme, theme: theme),
                  if (slots.length < requestedRuns)
                    _LowResultsNote(
                      found: slots.length,
                      requested: requestedRuns,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  for (var i = 0; i < slots.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TimeSlotCard(
                        slot: slots[i],
                        rank: i + 1,
                        unit: settings.unit,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.water_drop,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No suitable run windows found this week.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your preferences or '
                      'check back tomorrow.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRefresh() {
    _refresh();
  }

  Future<void> _refresh() async {
    final location = ref.read(locationProvider).location;
    if (location == null || _isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await ref.read(weatherProvider.notifier).fetchForecast(location);

      final weatherState = ref.read(weatherProvider);
      if (weatherState.errorMessage != null) {
        _showError(weatherState.errorMessage!);
        return;
      }

      final requestedRuns = ref.read(runSchedulerProvider).requestedRuns;
      await ref
          .read(runSchedulerProvider.notifier)
          .findSlots(numberOfRuns: requestedRuns);

      final scheduleState = ref.read(runSchedulerProvider);
      if (scheduleState.errorMessage != null) {
        _showError(scheduleState.errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Using cached forecast. Pull down to refresh.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowResultsNote extends StatelessWidget {
  const _LowResultsNote({
    required this.found,
    required this.requested,
    required this.theme,
    required this.colorScheme,
  });

  final int found;
  final int requested;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'We found $found good window${found == 1 ? '' : 's'} '
        'out of the $requested you requested. '
        "It's a tough weather week!",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
