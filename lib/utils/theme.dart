import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_spacing.dart';

const _appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF005235),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF55615C),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFF7FAF5),
  onSurface: Color(0xFF181D1A),
  primaryContainer: Color(0xFF1B6B4A),
  onPrimaryContainer: Color(0xFF9CE9BF),
  secondaryContainer: Color(0xFFD6E3DC),
  onSecondaryContainer: Color(0xFF181D1A),
  tertiary: Color(0xFF753134),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFD9E5DF),
  onTertiaryContainer: Color(0xFF181D1A),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surfaceContainerHighest: AppColors.surfaceContainer,
  onSurfaceVariant: Color(0xFF3F4943),
  outline: Color(0xFF6F7A72),
  outlineVariant: Color(0xFFBFC9C0),
  shadow: Color(0x0F181D1A),
  scrim: Color(0x66181D1A),
  inverseSurface: Color(0xFF2C312E),
  onInverseSurface: Color(0xFFEFF2ED),
  inversePrimary: Color(0xFF9CE9BF),
  surfaceTint: Color(0xFF005235),
);

TextTheme _textTheme(Color textColor, Color secondaryTextColor) {
  final base = GoogleFonts.manropeTextTheme().apply(
    bodyColor: textColor,
    displayColor: textColor,
  );

  return base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: textColor,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: textColor,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: textColor,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: textColor,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: secondaryTextColor,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: secondaryTextColor,
    ),
  );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _appColorScheme,
  scaffoldBackgroundColor: _appColorScheme.surface,
  textTheme: _textTheme(
    _appColorScheme.onSurface,
    _appColorScheme.onSurfaceVariant,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.surfaceContainerLowest,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: _appColorScheme.surface,
    foregroundColor: _appColorScheme.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    shadowColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: _textTheme(
      _appColorScheme.onSurface,
      _appColorScheme.onSurfaceVariant,
    ).titleLarge,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _appColorScheme.primaryContainer,
      foregroundColor: _appColorScheme.onPrimary,
      minimumSize: const Size(double.infinity, 56),
      shape: const StadiumBorder(),
      textStyle: _textTheme(
        _appColorScheme.onSurface,
        _appColorScheme.onSurfaceVariant,
      ).labelLarge,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _appColorScheme.primaryContainer,
      foregroundColor: _appColorScheme.onPrimary,
      minimumSize: const Size(double.infinity, 56),
      shape: const StadiumBorder(),
      textStyle: _textTheme(
        _appColorScheme.onSurface,
        _appColorScheme.onSurfaceVariant,
      ).labelLarge,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: AppColors.surfaceContainerLow,
      foregroundColor: _appColorScheme.primary,
      minimumSize: const Size(double.infinity, 56),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      textStyle: _textTheme(
        _appColorScheme.onSurface,
        _appColorScheme.onSurfaceVariant,
      ).labelLarge,
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.secondaryFixed,
    selectedColor: _appColorScheme.primaryContainer,
    secondarySelectedColor: _appColorScheme.primaryContainer,
    disabledColor: AppColors.surfaceContainer,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.dataPillPaddingH,
      vertical: AppSpacing.dataPillPaddingV,
    ),
    labelStyle: _textTheme(
      _appColorScheme.onSurface,
      _appColorScheme.onSurfaceVariant,
    ).labelSmall,
    secondaryLabelStyle: _textTheme(
      _appColorScheme.onSurface,
      _appColorScheme.onSurfaceVariant,
    ).labelSmall?.copyWith(color: _appColorScheme.onPrimary),
    side: BorderSide.none,
    shape: const StadiumBorder(),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceContainerLow,
    labelStyle: _textTheme(
      _appColorScheme.onSurface,
      _appColorScheme.onSurfaceVariant,
    ).labelMedium?.copyWith(letterSpacing: 1.4),
    hintStyle: _textTheme(
      _appColorScheme.onSurface,
      _appColorScheme.onSurfaceVariant,
    ).bodyMedium?.copyWith(color: _appColorScheme.onSurfaceVariant),
    prefixIconColor: _appColorScheme.onSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.inputField),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.inputField),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.inputField),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.inputField),
      borderSide: BorderSide.none,
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.inputField),
      borderSide: BorderSide.none,
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _appColorScheme.primary;
        }
        return _appColorScheme.secondaryContainer;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _appColorScheme.onPrimary;
        }
        return _appColorScheme.onSurface;
      }),
      textStyle: WidgetStatePropertyAll(
        _textTheme(
          _appColorScheme.onSurface,
          _appColorScheme.onSurfaceVariant,
        ).labelLarge,
      ),
      side: const WidgetStatePropertyAll(BorderSide.none),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.labelToContentGap,
          vertical: AppSpacing.dataPillPaddingH + 2,
        ),
      ),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: _appColorScheme.outlineVariant.withValues(alpha: 0.1),
    thickness: 1,
    space: 1,
  ),
);
