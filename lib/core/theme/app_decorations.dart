import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.backgroundCard,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [AppColors.shadowCard],
  );

  static const BoxDecoration heroCardDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [AppColors.shadowHero],
  );

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: AppColors.pageGradient,
  );

  static const BoxDecoration dialogTitleDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    ),
  );

  static const BoxDecoration pillButtonDecoration = BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.all(Radius.circular(25)),
    boxShadow: [AppColors.shadowButton],
  );
}
