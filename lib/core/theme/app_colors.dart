import 'package:flutter/material.dart';

class AppColors {
  // Primary palette (Dynamic Material You tonal scale)
  static const Color primary = Color(0xFF667EEA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8EAFE);
  static const Color onPrimaryContainer = Color(0xFF2A3372);

  // Secondary palette
  static const Color secondary = Color(0xFF764BA2);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF1E6FF);
  static const Color onSecondaryContainer = Color(0xFF4B2A72);

  // Tertiary palette
  static const Color tertiary = Color(0xFF1890FF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE6F7FF);
  static const Color onTertiaryContainer = Color(0xFF003A8C);

  // Neutral palette
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color outline = Color(0xFF79747E);

  // Semantic
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);

  // Backgrounds & Surface variants
  static const Color backgroundSurface = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color neutral10 = Color(0xFFFDFDFD);
  static const Color neutral20 = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF636366);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Modernized gradients (Premium 2026 Style)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8F9FA),
      Color(0xFFF3F4FF),
      Color(0xFFF8F4FF),
      Color(0xFFF8F9FA),
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  // Elevation System (Material You 2026)
  static const BoxShadow shadowLevel0 = BoxShadow(color: Colors.transparent);
  static const BoxShadow shadowLevel1 = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );
  static const BoxShadow shadowLevel3 = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const BoxShadow shadowLevel4 = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static const BoxShadow shadowLevel5 = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 32,
    offset: Offset(0, 16),
  );

  static const Color surfaceContainerHighest = Color(0xFFE7E0EC);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFFADB5BD);
  static const Color grey600 = Color(0xFF6C757D);

  // Aliases for retrofitting and fixing lints
  static const Color border = Color(0xFFE5E5EA);
  static const Color primary10 = Color(0xFFF3F4FF);
  static const Color primary20 = Color(0xFFE8EAFE);
  static const Color primary30 = Color(0xFFD1D7FF);
  static const Color primary90 = Color(0xFF36428B);
  static const Color info = Color(0xFF007AFF);
  static const Color backgroundDialog = Color(0xFFFFFFFF);
  static const BoxShadow shadowHero = shadowLevel3;
  static const BoxShadow shadowButton = shadowLevel2;
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF28A745)],
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFD32F2F)],
  );
  static const LinearGradient disabledGradient = LinearGradient(
    colors: [Color(0xFFE5E5EA), Color(0xFFD1D1D6)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
  );
  static const BoxShadow shadowCard = shadowLevel2;
}
