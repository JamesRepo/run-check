import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/utils/app_colors.dart';
import 'package:run_check/utils/app_radii.dart';
import 'package:run_check/utils/app_shadows.dart';
import 'package:run_check/utils/app_spacing.dart';

void main() {
  group('[Unit] AppColors', () {
    test('should expose the documented design token values', () {
      expect(AppColors.surfaceContainerLow, const Color(0xFFF1F5EF));
      expect(AppColors.surfaceContainerLowest, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceContainer, const Color(0xFFEBEFEA));
      expect(AppColors.secondaryFixed, const Color(0xFFD9E5DF));
      expect(AppColors.scoreExcellent, const Color(0xFF1B6B4A));
      expect(AppColors.scoreGood, const Color(0xCC1B6B4A));
      expect(AppColors.scoreFair, const Color(0xFFFBBF24));
      expect(AppColors.scorePoor, const Color(0xFF753134));
      expect(AppColors.sunnyIcon, const Color(0xFFF59E0B));
      expect(AppColors.cloudyIcon, const Color(0xFF94A3B8));
      expect(AppColors.rainIcon, const Color(0xFF60A5FA));
    });
  });

  group('[Unit] AppSpacing', () {
    test('should expose the documented spacing token values', () {
      expect(AppSpacing.screenPaddingH, 20);
      expect(AppSpacing.screenPaddingTop, 48);
      expect(AppSpacing.sectionGap, 48);
      expect(AppSpacing.cardGap, 24);
      expect(AppSpacing.cardPadding, 20);
      expect(AppSpacing.chipGap, 8);
      expect(AppSpacing.dataPillGap, 8);
      expect(AppSpacing.dataPillPaddingH, 12);
      expect(AppSpacing.dataPillPaddingV, 6);
      expect(AppSpacing.labelToContentGap, 16);
      expect(AppSpacing.settingsGroupPadding, 24);
    });
  });

  group('[Unit] AppRadii', () {
    test('should expose the documented radius token values', () {
      expect(AppRadii.card, 12);
      expect(AppRadii.button, 9999);
      expect(AppRadii.chip, 9999);
      expect(AppRadii.dataPill, 9999);
      expect(AppRadii.settingsGroup, 12);
      expect(AppRadii.inputField, 12);
    });
  });

  group('[Unit] AppShadows', () {
    test('should expose the documented editorial shadow', () {
      expect(AppShadows.editorialShadow.offset, const Offset(0, 8));
      expect(AppShadows.editorialShadow.blurRadius, 24);
      expect(AppShadows.editorialShadow.spreadRadius, -4);
      expect(AppShadows.editorialShadow.color, const Color(0x0F181D1A));
    });
  });
}
