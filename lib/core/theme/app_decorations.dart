import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;
}

class AppRadius {
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 28.0;
  static const double full = 9999.0;

  // Aliases for easier usage
  static const double xs = extraSmall;
  static const double sm = small;
  static const double md = medium;
  static const double lg = large;
  static const double xl = 28.0; // Same as extraLarge
  static const double huge = 48.0; // New size for major components

  static const BorderRadius roundedExtraSmall = BorderRadius.all(Radius.circular(extraSmall));
  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(small));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(large));
  static const BorderRadius roundedExtraLarge = BorderRadius.all(Radius.circular(extraLarge));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}


class AppDecorations {
  // Card decorations
  static const BoxDecoration cardFilled = BoxDecoration(
    color: AppColors.primaryContainer,
    borderRadius: AppRadius.roundedLarge,
  );

  static const BoxDecoration cardElevated1 = BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: AppRadius.roundedLarge,
    boxShadow: [AppColors.shadowLevel1],
  );

  static const BoxDecoration cardElevated2 = BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: AppRadius.roundedLarge,
    boxShadow: [AppColors.shadowLevel2],
  );

  static const BoxDecoration cardElevated3 = BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: AppRadius.roundedExtraLarge,
    boxShadow: [AppColors.shadowLevel3],
  );

  static BoxDecoration cardOutlined = BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: AppRadius.roundedLarge,
    border: Border.all(color: AppColors.border, width: 1.5),
  );

  // Hero card with Mesh Gradient
  static const BoxDecoration heroCardDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppRadius.roundedExtraLarge,
    boxShadow: [AppColors.shadowLevel3],
  );

  // Page backgrounds
  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: AppColors.meshGradient,
  );

  // Dialog decorations
  static const BoxDecoration dialogBackground = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.roundedExtraLarge,
    boxShadow: [AppColors.shadowLevel5],
  );

  // Button decorations
  static const BoxDecoration filledButtonDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: [AppColors.shadowLevel2],
  );

  static const BoxDecoration pillButtonDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: AppRadius.roundedFull,
    boxShadow: [AppColors.shadowLevel2],
  );

  static BoxDecoration buttonOutlined = BoxDecoration(
    borderRadius: AppRadius.roundedFull,
    border: Border.all(color: AppColors.primary, width: 1.5),
  );

  // Input decorations
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w400),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.neutral10,
      isDense: isDense,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: isDense ? AppSpacing.md : AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }


  // Modernized search input
  static InputDecoration searchInputDecoration({required String hintText}) {
    return inputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
      isDense: true,
    ).copyWith(
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
