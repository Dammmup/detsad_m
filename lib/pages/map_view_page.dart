import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/geolocation_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';

class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeolocationProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Карта геозоны', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: _buildMap(geoProvider),
      ),
    );
  }

  Widget _buildMap(GeolocationProvider geoProvider) {
    if (geoProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!geoProvider.enabled || !geoProvider.isPositionLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Symbols.location_off_rounded, size: 64, color: AppColors.grey400),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Геолокация отключена или местоположение не определено',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ).animate().fadeIn(),
      );
    }

    final userPosition = LatLng(
      geoProvider.currentPosition!.latitude,
      geoProvider.currentPosition!.longitude,
    );

    final targetPosition = LatLng(
      geoProvider.targetLatitude,
      geoProvider.targetLongitude,
    );

    final markers = {
      Marker(
        markerId: const MarkerId('userLocation'),
        position: userPosition,
        infoWindow: const InfoWindow(title: 'Вы здесь'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('targetLocation'),
        position: targetPosition,
        infoWindow: const InfoWindow(title: 'Детский сад'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    final circles = {
      Circle(
        circleId: const CircleId('geofence'),
        center: targetPosition,
        radius: geoProvider.radius,
        fillColor: AppColors.success.withValues(alpha: 0.2),
        strokeColor: AppColors.success,
        strokeWidth: 2,
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: userPosition,
        zoom: 15,
      ),
      markers: markers,
      circles: circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      padding: const EdgeInsets.only(top: 100),
    ).animate().fadeIn();
  }
}
