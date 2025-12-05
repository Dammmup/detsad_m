import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/geolocation_provider.dart';

class MapViewPage extends StatelessWidget {
  const MapViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeolocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта геозоны'),
      ),
      body: _buildMap(geoProvider),
    );
  }

  Widget _buildMap(GeolocationProvider geoProvider) {
    if (geoProvider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!geoProvider.enabled || !geoProvider.isPositionLoaded) {
      return const Center(
        child: Text(
          'Геолокация отключена или ваше местоположение не определено.',
          textAlign: TextAlign.center,
        ),
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
        infoWindow: const InfoWindow(title: 'Центр геозоны'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    final circles = {
      Circle(
        circleId: const CircleId('geofence'),
        center: targetPosition,
        radius: geoProvider.radius,
        fillColor: Colors.green.withAlpha(77),
        strokeColor: Colors.green,
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
    );
  }
}
