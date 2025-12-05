import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/geolocation_service.dart';

class GeolocationProvider with ChangeNotifier {
  final GeolocationService _geolocationService = GeolocationService();

  bool _enabled = false;
  double _targetLatitude = 0.0;
  double _targetLongitude = 0.0;
  double _radius = 100.0;
  bool _loading = false;
  String? _errorMessage;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isRequestingPermission = false;
  bool _hasPermission = false;
  bool _isServiceEnabled = false;


  bool get enabled => _enabled;
  double get targetLatitude => _targetLatitude;
  double get targetLongitude => _targetLongitude;
  double get radius => _radius;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  bool get isPositionLoaded => _currentPosition != null;
  bool get hasPermission => _hasPermission;
  bool get isServiceEnabled => _isServiceEnabled;
  bool get isLocationAvailable => _hasPermission && _isServiceEnabled && _currentPosition != null;
  bool get isWithinGeofence => _currentPosition != null
      ? checkGeofence(_currentPosition!.latitude, _currentPosition!.longitude)
      : false;


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

        if (_enabled) {
          await initializeLocation();
        } else {
          stopLocationUpdates();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _enabled = false; // Disable geofencing if settings can't be loaded
      stopLocationUpdates();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Initialize location services and check permissions
  Future<void> initializeLocation() async {
    // Check if location services are enabled on the device
    _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isServiceEnabled) {
      _errorMessage = 'Службы геолокации отключены на устройстве.';
      notifyListeners();
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && !_isRequestingPermission) {
      _isRequestingPermission = true;
      permission = await Geolocator.requestPermission();
      _isRequestingPermission = false;
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _hasPermission = false;
      _errorMessage = 'Разрешение на доступ к местоположению отклонено.';
      notifyListeners();
      return;
    } else {
      _hasPermission = true;
      _errorMessage = null;
    }

    // Start location updates
    await startLocationUpdates();
  }

  Future<void> startLocationUpdates() async {
    if (_positionStream != null) return; // Already started

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _errorMessage = null; // Clear previous errors
      notifyListeners();
    }, onError: (e) {
      // For temporary GPS issues, we don't set an error but keep trying
      // The position stream will continue to try to get updates
      // Only set error for actual permission or service issues
      if (e.toString().toLowerCase().contains('permission') || e.toString().toLowerCase().contains('denied')) {
        _errorMessage = 'Ошибка получения геолокации: $e';
      }
      notifyListeners();
    });
  }

  void stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
    _currentPosition = null;
    notifyListeners();
  }

  // Check if location is temporarily unavailable (for UI purposes)
  bool get isLocationTemporarilyUnavailable {
    return _enabled && _hasPermission && _isServiceEnabled && _currentPosition == null && _errorMessage == null;
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
  bool checkGeofence(double currentLat, double currentLon) {
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

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
