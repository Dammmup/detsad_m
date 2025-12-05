import '../constants/api_constants.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class ShiftsService {
  final ApiService _apiService = ApiService();

  // Get staff shifts
  Future<List<dynamic>> getStaffShifts(
      {String? staffId, String? startDate, String? endDate, String? date}) async {
    try {
      String url = ApiConstants.staffShifts;
      List<String> queryParams = [];

      if (staffId != null && staffId.isNotEmpty) queryParams.add('staffId=$staffId');
      if (startDate != null && startDate.isNotEmpty) queryParams.add('startDate=$startDate');
      if (endDate != null && endDate.isNotEmpty) queryParams.add('endDate=$endDate');
      if (date != null && date.isNotEmpty) queryParams.add('date=$date');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data;
        } else if (data is Map) {
          // If backend returns object with shifts array
          if (data['shifts'] != null && data['shifts'] is List) {
            return data['shifts'] as List<dynamic>;
          }
          // Return empty list if unexpected format
          return [];
        }
        return [];
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }

  // Check in
  Future<void> checkIn(String shiftId,
      {double? latitude, double? longitude, String? status}) async {
    try {
      if (shiftId.isEmpty) {
        throw Exception('ID смены не указан');
      }
      
      final data = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      if (status != null) {
        data['status'] = status; // 'on_time' or 'late'
      }

      final response = await _apiService.post(
        ApiConstants.staffShiftCheckin(shiftId),
        data: data,
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage = 'Ошибка отметки прихода. Код: ${response.statusCode}';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'].toString();
        } else if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'].toString();
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      String errorMessage = 'Ошибка отметки прихода';
      if (e.response?.data is Map) {
        final errorData = e.response!.data as Map;
        if (errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка отметки прихода: $e');
    }
  }

  // Check out
  Future<void> checkOut(String shiftId,
      {double? latitude, double? longitude, String? status}) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      if (status != null) {
        data['status'] = status;
      }

      final response = await _apiService.post(
        ApiConstants.staffShiftCheckout(shiftId),
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