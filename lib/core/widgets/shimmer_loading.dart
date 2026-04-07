import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double? borderRadius;
  final BoxShape shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonLoader.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral20,
      highlightColor: AppColors.neutral10,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(borderRadius ?? AppRadius.small)
              : null,
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardElevated1,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader.circle(size: 48),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 120, height: 16, borderRadius: AppRadius.extraSmall),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonLoader(width: 80, height: 12, borderRadius: AppRadius.extraSmall),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SkeletonLoader(width: double.infinity, height: 14, borderRadius: AppRadius.extraSmall),
          SizedBox(height: AppSpacing.sm),
          SkeletonLoader(width: 200, height: 14, borderRadius: AppRadius.extraSmall),
        ],
      ),
    );
  }
}
