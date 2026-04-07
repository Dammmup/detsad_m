import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../providers/geolocation_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';

class GeolocationStatusWidget extends StatelessWidget {
  const GeolocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final geolocationProvider = Provider.of<GeolocationProvider>(context);
    if (!geolocationProvider.enabled) return const SizedBox.shrink();

    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        color: AppColors.surface,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _buildStatus(context, geolocationProvider),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatus(BuildContext context, GeolocationProvider provider) {
    if (provider.loading) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Загрузка настроек...', 
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)
          ),
        ],
      );
    }

    if (!provider.isServiceEnabled || !provider.hasPermission) {
      return _StatusRow(
        icon: Symbols.location_off_rounded,
        color: AppColors.error,
        title: !provider.isServiceEnabled ? 'GPS отключен' : 'Нет доступа',
        subtitle: 'Требуется для отметки посещения',
      );
    }

    if (provider.isLocationTemporarilyUnavailable || (!provider.isPositionLoaded && provider.enabled)) {
      return const _StatusRow(
        icon: Symbols.location_searching_rounded,
        color: AppColors.secondary,
        title: 'Определяем локацию...',
        subtitle: 'Ожидание сигнала GPS',
        isLoading: true,
      );
    }

    final pos = provider.currentPosition!;
    final isInZone = provider.checkGeofence(pos.latitude, pos.longitude);
    final distance = provider.calculateDistance(pos.latitude, pos.longitude);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isInZone ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isInZone ? Symbols.check_circle_rounded : Symbols.wrong_location_rounded,
            color: isInZone ? AppColors.success : AppColors.error,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInZone ? 'Вы в рабочей зоне' : 'Вне рабочей зоны',
                style: AppTypography.titleSmall.copyWith(
                  color: isInZone ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${distance.toStringAsFixed(0)} м от офиса',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/map'),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.map_rounded, 
                color: AppColors.primary,
                size: 20
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
            ? SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(color)
                )
              )
            : Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: AppTypography.labelLarge.copyWith(
                  color: color, 
                  fontWeight: FontWeight.w700
                )
              ),
              Text(
                subtitle, 
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
              ),
            ],
          ),
        ),
      ],
    );
  }
}
