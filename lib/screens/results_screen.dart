import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/settings_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_spacing.dart';
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
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: colorScheme.primaryContainer),
          tooltip: 'Back',
        ),
        title: Text(
          'Your Best Runs',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: <Widget>[
          if (_isRefreshing)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.dataPillPaddingH),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primaryContainer,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _handleRefresh,
              icon: Icon(Icons.refresh, color: colorScheme.primaryContainer),
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
                  horizontal: AppSpacing.screenPaddingH,
                ),
                children: <Widget>[
                  const SizedBox(height: 32),
                  _EditorialHeader(theme: theme, colorScheme: colorScheme),
                  const SizedBox(height: 32),
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
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.cardGap,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sectionGap,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.water_drop,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.labelToContentGap),
                    Text(
                      'No suitable run windows found this week.',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.chipGap),
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

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader({required this.theme, required this.colorScheme});

  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'OPTIMAL WINDOWS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.chipGap),
        Text(
          'Recommended for your weekly gallop.',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.colorScheme, required this.theme});

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.dataPillPaddingV + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.dataPillGap),
          Expanded(
            child: Text(
              'Using cached forecast. Pull down to refresh.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: Text(
        'We found $found good window${found == 1 ? '' : 's'} '
        'out of the $requested you requested. '
        "It's a tough weather week!",
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
