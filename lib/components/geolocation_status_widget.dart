import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/geolocation_provider.dart';

class GeolocationStatusWidget extends StatelessWidget {
  const GeolocationStatusWidget({Key? key}) : super(key: key);

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final geolocationProvider = Provider.of<GeolocationProvider>(context);

    if (!geolocationProvider.enabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Position?>(
        future: _getCurrentPosition(),
        builder: (context, snapshot) {
          if (geolocationProvider.loading) {
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

          if (!snapshot.hasData) {
            return Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Геолокация недоступна',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Включите GPS для отметки посещения',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final position = snapshot.data!;
          final isInZone = geolocationProvider.isWithinGeofence(
            position.latitude,
            position.longitude,
          );
          final distance = geolocationProvider.calculateDistance(
            position.latitude,
            position.longitude,
          );

          return Row(
            children: [
              Icon(
                isInZone ? Icons.check_circle : Icons.error,
                color: isInZone ? Colors.green : Colors.red,
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
                        color: isInZone ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '${distance.toStringAsFixed(0)} м от офиса (разрешено ${geolocationProvider.radius.toStringAsFixed(0)} м)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (!isInZone)
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
            ],
          );
        },
      ),
    );
  }
}
