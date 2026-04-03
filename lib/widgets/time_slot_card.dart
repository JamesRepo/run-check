import 'package:flutter/material.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/user_preferences.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_shadows.dart';
import 'package:run_check/utils/app_spacing.dart';
import 'package:run_check/utils/temperature_utils.dart';

class TimeSlotCard extends StatelessWidget {
  const TimeSlotCard({
    required this.slot,
    required this.rank,
    required this.unit,
    super.key,
  });

  final TimeSlot slot;
  final int rank;
  final TemperatureUnit unit;

  static const _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const <BoxShadow>[AppShadows.editorialShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _RankBadge(rank: rank),
                  const SizedBox(width: AppSpacing.labelToContentGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _formatDate(slot.startTime),
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            Icon(
                              _weatherIcon(slot.weatherCode),
                              size: 22,
                              color: _weatherIconColor(slot.weatherCode),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.chipGap),
                        Text(
                          '${_formatTime(slot.startTime)}'
                          ' – '
                          '${_formatTime(slot.endTime)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.labelToContentGap),
                        Wrap(
                          spacing: AppSpacing.dataPillGap,
                          runSpacing: AppSpacing.dataPillGap,
                          children: <Widget>[
                            _DataPill(
                              icon: Icons.thermostat_outlined,
                              label: _formatTemperature(),
                            ),
                            _DataPill(
                              icon: Icons.water_drop_outlined,
                              label: '${slot.precipitationProbability}%',
                            ),
                            _DataPill(
                              icon: Icons.air,
                              label: '${slot.windSpeed.round()} km/h',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(height: 6, color: _scoreColor(slot.score)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final weekday = _weekdays[dt.weekday - 1];
    final day = dt.day;
    final month = _months[dt.month - 1];
    return '$weekday, $day $month';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTemperature() {
    final isFahrenheit = unit == TemperatureUnit.fahrenheit;
    final value = isFahrenheit
        ? celsiusToFahrenheit(slot.temperature)
        : slot.temperature;
    final suffix = isFahrenheit ? '°F' : '°C';
    return '${value.round()}$suffix';
  }

  static IconData _weatherIcon(int code) {
    if (code <= 1) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.cloud;
    if (code <= 55) return Icons.water_drop;
    if (code <= 65) return Icons.water_drop;
    if (code <= 75) return Icons.ac_unit;
    if (code <= 82) return Icons.water_drop;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud;
  }

  static Color _weatherIconColor(int code) {
    if (code <= 1) {
      return AppColors.sunnyIcon;
    }
    if (code <= 48) {
      return AppColors.cloudyIcon;
    }
    return AppColors.rainIcon;
  }

  static Color _scoreColor(double score) {
    if (score >= 0.7) {
      return AppColors.scoreExcellent;
    }
    if (score >= 0.4) {
      return AppColors.scoreFair;
    }
    return AppColors.scorePoor;
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.dataPillPaddingH,
        vertical: AppSpacing.dataPillPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.dataPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.dataPillGap),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
