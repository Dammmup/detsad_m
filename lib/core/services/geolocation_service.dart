import '../constants/api_constants.dart';
import 'api_service.dart';
import 'dart:io';
import 'dart:math';

class GeolocationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> getGeolocationSettings() async {
    try {
      final response = await _apiService.get(ApiConstants.settingsGeolocation);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения настроек геолокации: $e');
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371e3;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  bool isWithinGeofence({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    required double radius,
  }) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radius;
  }
}
