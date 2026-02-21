import 'package:flutter/material.dart';

class AppColors {
  // Primary palette (frontend gradient)
  static const Color primary = Color(0xFF667eea);
  static const Color primaryDark = Color(0xFF764ba2);
  static const Color primaryLight = Color(0xFFe8eaff);
  static const Color accent = Color(0xFF1890ff);
  static const Color accentDark = Color(0xFF096dd9);

  // Backgrounds
  static const Color background = Color(0xFFF0F2F5);
  static const Color backgroundSurface = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundAppBar = Color(0xFF667eea);

  // Text
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF52c41a);
  static const Color warning = Color(0xFFfaad14);
  static const Color error = Color(0xFFff4d4f);
  static const Color info = Color(0xFF1890ff);

  // Borders
  static const Color border = Color(0xFFe2e8f0);
  static const Color borderFocused = Color(0xFF667eea);

  // Icons
  static const Color iconPrimary = Color(0xFF212529);
  static const Color iconSecondary = Color(0xFF6B7280);
  static const Color iconOnPrimary = Color(0xFFFFFFFF);

  // Buttons
  static const Color buttonPrimary = Color(0xFF667eea);
  static const Color buttonPrimaryDisabled = Color(0xFFcccccc);
  static const Color buttonSecondary = Color(0xFF6B7280);
  static const Color buttonSecondaryDisabled = Color(0xFFe2e8f0);

  // Neutral greys
  static const Color grey700 = Color(0xFF374151);
  static const Color grey600 = Color(0xFF495057);
  static const Color grey500 = Color(0xFF6c757d);
  static const Color grey300 = Color(0xFFdee2e6);
  static const Color grey250 = Color(0xFFe2e8f0);
  static const Color grey200 = Color(0xFFe9ecef);
  static const Color grey100 = Color(0xFFf8f9fa);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  );

  static const LinearGradient disabledGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xFFcccccc), Color(0xFF999999)],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xFFf5f7fa), Color(0xFFebf0f5)],
  );

  // Shadows
  static const BoxShadow shadowSubtle = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowCard = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 10,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowCardHover = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 20,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowHero = BoxShadow(
    color: Color(0x33667eea),
    blurRadius: 15,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );

  static const BoxShadow shadowHeroHover = BoxShadow(
    color: Color(0x4D667eea),
    blurRadius: 25,
    spreadRadius: 0,
    offset: Offset(0, 8),
  );

  static const BoxShadow shadowButton = BoxShadow(
    color: Color(0x33667eea),
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 3),
  );

  static const BoxShadow shadowButtonHover = BoxShadow(
    color: Color(0x4D667eea),
    blurRadius: 15,
    spreadRadius: 0,
    offset: Offset(0, 5),
  );

  static const BoxShadow shadowDialog = BoxShadow(
    color: Color(0x29000000),
    blurRadius: 30,
    spreadRadius: 0,
    offset: Offset(0, 8),
  );

  static const BoxShadow shadowAppBar = BoxShadow(
    color: Color(0x1A667eea),
    blurRadius: 10,
    spreadRadius: 0,
    offset: Offset(0, 2),
  );
}
