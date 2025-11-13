import 'package:flutter/material.dart';
import '../core/services/geolocation_service.dart';

class GeolocationProvider with ChangeNotifier {
  final GeolocationService _geolocationService = GeolocationService();

  bool _enabled = false;
  double _targetLatitude = 0.0;
  double _targetLongitude = 0.0;
  double _radius = 100.0;
  bool _loading = false;
  String? _errorMessage;

  bool get enabled => _enabled;
  double get targetLatitude => _targetLatitude;
  double get targetLongitude => _targetLongitude;
  double get radius => _radius;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  // Load geolocation settings from backend
  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();

    try {
      final settings = await _geolocationService.getGeolocationSettings();
      
      if (settings != null) {
        _enabled = settings['enabled'] ?? false;
        _targetLatitude = settings['coordinates']?['latitude']?.toDouble() ?? 0.0;
        _targetLongitude = settings['coordinates']?['longitude']?.toDouble() ?? 0.0;
        _radius = settings['radius']?.toDouble() ?? 100.0;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _enabled = false; // Disable geofencing if settings can't be loaded
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Calculate distance from current position to target
  double calculateDistance(double currentLat, double currentLon) {
    return _geolocationService.calculateDistance(
      currentLat,
      currentLon,
      _targetLatitude,
      _targetLongitude,
    );
  }

  // Check if user is within geofence
  bool isWithinGeofence(double currentLat, double currentLon) {
    if (!_enabled) return true; // If geofencing is disabled, allow
    
    return _geolocationService.isWithinGeofence(
      userLat: currentLat,
      userLon: currentLon,
      targetLat: _targetLatitude,
      targetLon: _targetLongitude,
      radius: _radius,
    );
  }

  // Get status text based on distance
  String getStatusText(double currentLat, double currentLon) {
    if (!_enabled) return 'Геолокация отключена';
    
    final distance = calculateDistance(currentLat, currentLon);
    
    if (distance <= _radius) {
      return 'В зоне (${distance.toStringAsFixed(0)}м от офиса)';
    } else {
      return 'Вне зоны (${distance.toStringAsFixed(0)}м от офиса)';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
