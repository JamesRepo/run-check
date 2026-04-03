import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/theme.dart';

void main() {
  group('[Widget] appTheme', () {
    testWidgets('should configure the expected manual color scheme', (
      WidgetTester tester,
    ) async {
      await _pumpThemeHost(tester);

      final colorScheme = appTheme.colorScheme;

      expect(colorScheme.brightness, Brightness.light);
      expect(colorScheme.primary, const Color(0xFF005235));
      expect(colorScheme.primaryContainer, const Color(0xFF1B6B4A));
      expect(colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(colorScheme.onPrimaryContainer, const Color(0xFF9CE9BF));
      expect(colorScheme.secondary, const Color(0xFF55615C));
      expect(colorScheme.secondaryContainer, const Color(0xFFD6E3DC));
      expect(colorScheme.surface, const Color(0xFFF7FAF5));
      expect(colorScheme.onSurface, const Color(0xFF181D1A));
      expect(colorScheme.onSurfaceVariant, const Color(0xFF3F4943));
      expect(colorScheme.error, const Color(0xFFBA1A1A));
      expect(colorScheme.errorContainer, const Color(0xFFFFDAD6));
      expect(colorScheme.outline, const Color(0xFF6F7A72));
      expect(colorScheme.outlineVariant, const Color(0xFFBFC9C0));
    });

    testWidgets('should configure the documented Manrope text styles', (
      WidgetTester tester,
    ) async {
      await _pumpThemeHost(tester);

      final textTheme = appTheme.textTheme;

      expect(textTheme.displaySmall?.fontSize, 36);
      expect(textTheme.displaySmall?.fontWeight, FontWeight.w800);
      expect(textTheme.headlineLarge?.fontSize, 30);
      expect(textTheme.headlineLarge?.fontWeight, FontWeight.w800);
      expect(textTheme.headlineLarge?.letterSpacing, -0.6);
      expect(textTheme.headlineMedium?.fontSize, 24);
      expect(textTheme.headlineMedium?.fontWeight, FontWeight.w800);
      expect(textTheme.headlineMedium?.letterSpacing, -0.4);
      expect(textTheme.titleLarge?.fontSize, 18);
      expect(textTheme.titleLarge?.fontWeight, FontWeight.w700);
      expect(textTheme.titleMedium?.fontSize, 20);
      expect(textTheme.titleMedium?.fontWeight, FontWeight.w700);
      expect(textTheme.titleMedium?.letterSpacing, -0.3);
      expect(textTheme.bodyLarge?.fontSize, 16);
      expect(textTheme.bodyLarge?.fontWeight, FontWeight.w500);
      expect(textTheme.bodyMedium?.fontSize, 14);
      expect(textTheme.bodyMedium?.fontWeight, FontWeight.w500);
      expect(textTheme.labelLarge?.fontSize, 14);
      expect(textTheme.labelLarge?.fontWeight, FontWeight.w700);
      expect(textTheme.labelMedium?.fontSize, 10);
      expect(textTheme.labelMedium?.fontWeight, FontWeight.w600);
      expect(textTheme.labelSmall?.fontSize, 12);
      expect(textTheme.labelSmall?.fontWeight, FontWeight.w600);
      expect(textTheme.bodyLarge?.fontFamily, contains('Manrope'));
    });

    testWidgets(
      'should configure cards with tonal layering and rounded corners',
      (WidgetTester tester) async {
        await _pumpThemeHost(tester);

        final cardTheme = appTheme.cardTheme;

        expect(cardTheme.color, AppColors.surfaceContainerLowest);
        expect(cardTheme.elevation, 0);
        expect(cardTheme.margin, EdgeInsets.zero);

        final shape = cardTheme.shape! as RoundedRectangleBorder;
        final borderRadius = shape.borderRadius as BorderRadius;

        expect(borderRadius.topLeft, const Radius.circular(AppRadii.card));
        expect(borderRadius.topRight, const Radius.circular(AppRadii.card));
        expect(borderRadius.bottomLeft, const Radius.circular(AppRadii.card));
        expect(borderRadius.bottomRight, const Radius.circular(AppRadii.card));
      },
    );

    testWidgets('should configure pill button themes with 56dp height', (
      WidgetTester tester,
    ) async {
      await _pumpThemeHost(tester);

      final elevatedButtonStyle = appTheme.elevatedButtonTheme.style!;
      final filledButtonStyle = appTheme.filledButtonTheme.style!;

      expect(
        elevatedButtonStyle.backgroundColor?.resolve(<WidgetState>{}),
        appTheme.colorScheme.primaryContainer,
      );
      expect(
        elevatedButtonStyle.foregroundColor?.resolve(<WidgetState>{}),
        appTheme.colorScheme.onPrimary,
      );
      expect(
        elevatedButtonStyle.minimumSize?.resolve(<WidgetState>{})?.height,
        56,
      );
      expect(
        elevatedButtonStyle.shape?.resolve(<WidgetState>{}),
        isA<StadiumBorder>(),
      );

      expect(
        filledButtonStyle.backgroundColor?.resolve(<WidgetState>{}),
        appTheme.colorScheme.primaryContainer,
      );
      expect(
        filledButtonStyle.foregroundColor?.resolve(<WidgetState>{}),
        appTheme.colorScheme.onPrimary,
      );
      expect(
        filledButtonStyle.minimumSize?.resolve(<WidgetState>{})?.height,
        56,
      );
      expect(
        filledButtonStyle.shape?.resolve(<WidgetState>{}),
        isA<StadiumBorder>(),
      );
    });

    testWidgets('should configure the shared chip and scaffold styling', (
      WidgetTester tester,
    ) async {
      await _pumpThemeHost(tester);

      final chipTheme = appTheme.chipTheme;
      final appBarTheme = appTheme.appBarTheme;

      expect(appTheme.scaffoldBackgroundColor, const Color(0xFFF7FAF5));
      expect(chipTheme.backgroundColor, AppColors.secondaryFixed);
      expect(chipTheme.side, BorderSide.none);
      expect(chipTheme.shape, const StadiumBorder());
      expect(appBarTheme.backgroundColor, const Color(0xFFF7FAF5));
      expect(appBarTheme.elevation, 0);
      expect(appBarTheme.shadowColor, Colors.transparent);
    });
  });
}

Future<void> _pumpThemeHost(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
}
