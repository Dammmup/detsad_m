import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Primary Font Surface: Inter for readability
  // Heading Font Surface: Outfit for premium look

  static TextStyle _inter(double size, FontWeight weight, double height, Color color, [double spacing = 0]) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: spacing,
  );

  static TextStyle get displayLarge => _inter(57, FontWeight.w400, 64/57, AppColors.textPrimary, -0.25);
  static TextStyle get displayMedium => _inter(45, FontWeight.w400, 52/45, AppColors.textPrimary);
  static TextStyle get displaySmall => _inter(36, FontWeight.w400, 44/36, AppColors.textPrimary);

  static TextStyle get headlineLarge => _inter(32, FontWeight.w400, 40/32, AppColors.textPrimary);
  static TextStyle get headlineMedium => _inter(28, FontWeight.w400, 36/28, AppColors.textPrimary);
  static TextStyle get headlineSmall => _inter(24, FontWeight.w400, 32/24, AppColors.textPrimary);

  static TextStyle get titleLarge => _inter(22, FontWeight.w400, 28/22, AppColors.textPrimary);
  static TextStyle get titleMedium => _inter(16, FontWeight.w500, 24/16, AppColors.textPrimary, 0.15);
  static TextStyle get titleSmall => _inter(14, FontWeight.w500, 20/14, AppColors.textPrimary, 0.1);

  static TextStyle get bodyLarge => _inter(16, FontWeight.w400, 24/16, AppColors.textPrimary, 0.5);
  static TextStyle get bodyMedium => _inter(14, FontWeight.w400, 20/14, AppColors.textSecondary, 0.25);
  static TextStyle get bodySmall => _inter(12, FontWeight.w400, 16/12, AppColors.textTertiary, 0.4);

  static TextStyle get labelLarge => _inter(14, FontWeight.w500, 20/14, AppColors.textPrimary, 0.1);
  static TextStyle get labelMedium => _inter(12, FontWeight.w500, 16/12, AppColors.textSecondary, 0.5);
  static TextStyle get labelSmall => _inter(11, FontWeight.w500, 16/11, AppColors.textTertiary, 0.5);

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
