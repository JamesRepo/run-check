import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_spacing.dart';
import 'package:run_check/widgets/location_bottom_sheet.dart';
import 'package:run_check/widgets/run_count_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedRunCount = 3;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationState = ref.watch(locationProvider);
    final location = locationState.location;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.location_on, color: colorScheme.primaryContainer),
            const SizedBox(width: AppSpacing.chipGap),
            Text(
              'RunCheck',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: Icon(Icons.settings, color: colorScheme.primaryContainer),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.screenPaddingTop),
                    Text(
                      'Plan your week',
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.chipGap),
                    _LocationSection(
                      locationLabel: location?.displayName,
                      onTap: () => _showLocationBottomSheet(context),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const _HeroBanner(),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Text(
                      'How many runs this week?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.labelToContentGap),
                    RunCountSelector(
                      selectedCount: _selectedRunCount,
                      onSelected: (int value) {
                        setState(() {
                          _selectedRunCount = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    const Spacer(),
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.only(bottom: 20),
                      child: FilledButton(
                        onPressed: location == null || _isSubmitting
                            ? null
                            : _handleFindRuns,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.surfaceContainerLowest,
                                  ),
                                ),
                              )
                            : Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.chipGap,
                                children: <Widget>[
                                  const Text('Find my best runs'),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      showDragHandle: true,
      builder: (BuildContext context) {
        return const LocationBottomSheet();
      },
    );
  }

  Future<void> _handleFindRuns() async {
    final location = ref.read(locationProvider).location;
    if (location == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(weatherProvider.notifier).fetchForecast(location);
      final weatherState = ref.read(weatherProvider);
      if (weatherState.errorMessage != null) {
        _showError(weatherState.errorMessage!);
        return;
      }

      await ref
          .read(runSchedulerProvider.notifier)
          .findSlots(numberOfRuns: _selectedRunCount);
      final scheduleState = ref.read(runSchedulerProvider);
      if (scheduleState.errorMessage != null) {
        _showError(scheduleState.errorMessage!);
        return;
      }

      if (!mounted) {
        return;
      }

      unawaited(context.push('/results'));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.locationLabel, required this.onTap});

  final String? locationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.near_me_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.chipGap),
              Expanded(
                child: Text(
                  locationLabel ?? 'Tap to set your location',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.chipGap),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  static const _heroImagePath = 'assets/images/hero_runner.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(_heroImagePath, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(),
                  Text(
                    'READY TO RUN?',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.chipGap),
                  Text(
                    'Find your perfect window today',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
