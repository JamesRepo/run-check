import 'package:flutter/material.dart';
import 'package:run_check/models/time_slot.dart';
import 'package:run_check/models/user_preferences.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _RankBadge(rank: rank, colorScheme: colorScheme),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _formatDate(slot.startTime),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(
                        _weatherIcon(slot.weatherCode),
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(slot.startTime)}'
                    ' – '
                    '${_formatTime(slot.endTime)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      _InfoChip(
                        icon: Icons.thermostat_outlined,
                        label: _formatTemperature(),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.water_drop_outlined,
                        label: '${slot.precipitationProbability}%',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.air,
                        label: '${slot.windSpeed.round()} km/h',
                        colorScheme: colorScheme,
                      ),
                      const Spacer(),
                      _ScoreDot(score: slot.score),
                    ],
                  ),
                ],
              ),
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
    final value =
        isFahrenheit
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
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.colorScheme});

  final int rank;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ScoreDot extends StatelessWidget {
  const _ScoreDot({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (score >= 0.7) {
      color = Colors.green;
    } else if (score >= 0.4) {
      color = Colors.amber;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
