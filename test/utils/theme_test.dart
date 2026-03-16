import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/theme.dart';

void main() {
  group('[Unit] appTheme', () {
    test('should configure the expected light brand color scheme', () {
      final expectedColorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6B4A),
      ).copyWith(brightness: Brightness.light);

      expect(appTheme.colorScheme.brightness, Brightness.light);
      expect(appTheme.colorScheme, expectedColorScheme);
    });

    test('should configure the documented text theme styles', () {
      final textTheme = appTheme.textTheme;

      expect(textTheme.headlineLarge?.fontSize, 24);
      expect(textTheme.headlineLarge?.fontWeight, FontWeight.bold);
      expect(textTheme.headlineMedium?.fontSize, 20);
      expect(textTheme.headlineMedium?.fontWeight, FontWeight.bold);
      expect(textTheme.titleMedium?.fontSize, 16);
      expect(textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(textTheme.bodyLarge?.fontSize, 16);
      expect(textTheme.bodyMedium?.fontSize, 14);
      expect(textTheme.labelLarge?.fontSize, 14);
      expect(textTheme.labelLarge?.fontWeight, FontWeight.w600);
    });

    test(
      'should configure the card theme with rounded corners and elevation',
      () {
        final cardTheme = appTheme.cardTheme;

        expect(cardTheme.elevation, 1);

        final shape = cardTheme.shape;
        expect(shape, isA<RoundedRectangleBorder>());

        final roundedShape = shape! as RoundedRectangleBorder;
        final borderRadius = roundedShape.borderRadius as BorderRadius;

        expect(borderRadius.topLeft, const Radius.circular(12));
        expect(borderRadius.topRight, const Radius.circular(12));
        expect(borderRadius.bottomLeft, const Radius.circular(12));
        expect(borderRadius.bottomRight, const Radius.circular(12));
      },
    );

    test(
      'should configure elevated buttons with brand styling and minimum height',
      () {
        final buttonStyle = appTheme.elevatedButtonTheme.style!;

        expect(
          buttonStyle.backgroundColor?.resolve({}),
          const Color(0xFF1B6B4A),
        );
        expect(buttonStyle.foregroundColor?.resolve({}), Colors.white);
        expect(buttonStyle.minimumSize?.resolve({})?.height, 48);
        expect(buttonStyle.textStyle?.resolve({})?.fontWeight, FontWeight.w600);
        expect(buttonStyle.textStyle?.resolve({})?.fontSize, 14);

        final shape = buttonStyle.shape?.resolve({});
        expect(shape, isA<RoundedRectangleBorder>());

        final roundedShape = shape! as RoundedRectangleBorder;
        final borderRadius = roundedShape.borderRadius as BorderRadius;

        expect(borderRadius.topLeft, const Radius.circular(8));
        expect(borderRadius.topRight, const Radius.circular(8));
        expect(borderRadius.bottomLeft, const Radius.circular(8));
        expect(borderRadius.bottomRight, const Radius.circular(8));
      },
    );
  });
}
