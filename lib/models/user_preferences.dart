class UserPreferences {
  UserPreferences({
    this.unit = TemperatureUnit.celsius,
    List<String> preferredPeriods = defaultPreferredPeriods,
    this.runDurationMinutes = 60,
    this.cyclistMode = false,
  }) : preferredPeriods = List<String>.unmodifiable(preferredPeriods);

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final periods = json['preferredPeriods'] as List<dynamic>?;

    return UserPreferences(
      unit: TemperatureUnitX.fromName(json['unit'] as String?),
      preferredPeriods: periods == null
          ? defaultPreferredPeriods
          : periods.whereType<String>().toList(growable: false),
      runDurationMinutes: _parseInt(json['runDurationMinutes']) ?? 60,
      cyclistMode: json['cyclistMode'] as bool? ?? false,
    );
  }

  final TemperatureUnit unit;
  final List<String> preferredPeriods;
  final int runDurationMinutes;
  final bool cyclistMode;

  static const defaultPreferredPeriods = <String>[
    'morning',
    'afternoon',
    'evening',
  ];

  static const _sentinel = Object();

  UserPreferences copyWith({
    TemperatureUnit? unit,
    Object? preferredPeriods = _sentinel,
    int? runDurationMinutes,
    bool? cyclistMode,
  }) {
    return UserPreferences(
      unit: unit ?? this.unit,
      preferredPeriods: identical(preferredPeriods, _sentinel)
          ? this.preferredPeriods
          : preferredPeriods! as List<String>,
      runDurationMinutes: runDurationMinutes ?? this.runDurationMinutes,
      cyclistMode: cyclistMode ?? this.cyclistMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'unit': unit.name,
      'preferredPeriods': preferredPeriods,
      'runDurationMinutes': runDurationMinutes,
      'cyclistMode': cyclistMode,
    };
  }

  static int? _parseInt(Object? value) {
    if (value case final num numericValue) {
      return numericValue.toInt();
    }

    return null;
  }
}

enum TemperatureUnit { celsius, fahrenheit }

extension TemperatureUnitX on TemperatureUnit {
  static TemperatureUnit fromName(String? value) {
    return TemperatureUnit.values.firstWhere(
      (unit) => unit.name == value,
      orElse: () => TemperatureUnit.celsius,
    );
  }
}
