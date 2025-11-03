import '../constants/api_constants.dart';
import '../../models/attendance_model.dart'; // Используем существующую модель
import 'api_service.dart';
import 'dart:io';

class ShiftsService {
  final ApiService _apiService = ApiService();

  // Get staff shifts
  Future<List<dynamic>> getStaffShifts({String? staffId, String? startDate, String? endDate}) async {
    try {
      String url = ApiConstants.staffShifts;
      List<String> queryParams = [];

      if (staffId != null) queryParams.add('staffId=$staffId');
      if (startDate != null) queryParams.add('startDate=$startDate');
      if (endDate != null) queryParams.add('endDate=$endDate');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data;
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
 }

  // Check in
  Future<void> checkIn(String shiftId, {double? latitude, double? longitude}) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      
      final response = await _apiService.post(
        '${ApiConstants.staffShiftCheckin(shiftId)}',
        data: data,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка отметки прихода');
      }
    } catch (e) {
      throw Exception('Ошибка отметки прихода: $e');
    }
  }

  // Check out
  Future<void> checkOut(String shiftId, {double? latitude, double? longitude}) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      
      final response = await _apiService.post(
        '${ApiConstants.staffShiftCheckout(shiftId)}',
        data: data,
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка отметки ухода');
      }
    } catch (e) {
      throw Exception('Ошибка отметки ухода: $e');
    }
  }
}