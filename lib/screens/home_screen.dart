import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/providers/location_provider.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/providers/weather_provider.dart';
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
        title: Text(
          'RunCheck',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 24),
              _LocationSection(
                locationLabel: location?.displayName,
                onTap: () => _showLocationBottomSheet(context),
              ),
              const SizedBox(height: 24),
              Text(
                'How many runs this week?',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              RunCountSelector(
                selectedCount: _selectedRunCount,
                onSelected: (int value) {
                  setState(() {
                    _selectedRunCount = value;
                  });
                },
              ),
              const Spacer(),
              SafeArea(
                top: false,
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
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Find my best runs'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
    final hasLocation = locationLabel != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                hasLocation ? locationLabel! : 'Tap to set your location',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: hasLocation
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(Icons.edit_outlined, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
