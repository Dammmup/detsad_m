import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../providers/geolocation_provider.dart';

class GeolocationStatusWidget extends StatelessWidget {
  const GeolocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final geolocationProvider = Provider.of<GeolocationProvider>(context);

    if (!geolocationProvider.enabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: _buildStatus(context, geolocationProvider),
    );
  }

  Widget _buildStatus(BuildContext context, GeolocationProvider provider) {
    if (provider.loading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Загрузка настроек геолокации...'),
        ],
      );
    }

    if (!provider.isServiceEnabled) {
      return Row(
        children: [
          const Icon(Icons.location_disabled, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Службы геолокации отключены',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  'Включите службы геолокации на устройстве',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!provider.hasPermission) {
      return Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Нет разрешения на геолокацию',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  provider.errorMessage ??
                      'Предоставьте разрешение на доступ к местоположению',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (provider.isLocationTemporarilyUnavailable) {
      return Row(
        children: [
          const Icon(Icons.location_searching, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Поиск местоположения...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                Text(
                  'GPS сигнал недоступен, но разрешения предоставлены',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (provider.errorMessage != null && !provider.isPositionLoaded) {
      return Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Геолокация недоступна',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  provider.errorMessage ?? 'Включите GPS для отметки посещения',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (!provider.isPositionLoaded && provider.enabled) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('Поиск местоположения...'),
          ),
        ],
      );
    }

    final position = provider.currentPosition!;
    final isInZone =
        provider.checkGeofence(position.latitude, position.longitude);
    final distance =
        provider.calculateDistance(position.latitude, position.longitude);

    return Row(
      children: [
        Icon(
          isInZone ? Icons.check_circle : Icons.error,
          color: isInZone ? AppColors.success : AppColors.error,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInZone ? 'В рабочей зоне' : 'Вне рабочей зоны',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isInZone ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                '${distance.toStringAsFixed(0)} м от офиса (разрешено ${provider.radius.toStringAsFixed(0)} м)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.map,
            color: isInZone ? AppColors.success : AppColors.error,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/map');
          },
        ),
      ],
    );
  }
}
