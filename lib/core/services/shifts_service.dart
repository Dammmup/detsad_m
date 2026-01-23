import '../constants/api_constants.dart';
import 'api_service.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class ShiftsService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getStaffShifts(
      {String? staffId,
      String? startDate,
      String? endDate,
      String? date}) async {
    try {
      String url = ApiConstants.staffShifts;
      List<String> queryParams = [];
      if (staffId != null && staffId.isNotEmpty) {
        queryParams.add('staffId=$staffId');
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams.add('endDate=$endDate');
      }
      if (date != null && date.isNotEmpty) {
        queryParams.add('date=$date');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('shifts')) {
          return data['shifts'] as List<dynamic>;
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Ошибка получения данных: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Ошибка получения данных: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }

  Future<List<dynamic>> getStaffAttendanceTrackingRecords(
      {String? staffId,
      String? startDate,
      String? endDate,
      String? date}) async {
    try {
      String url = ApiConstants.staffAttendanceTracking;
      List<String> queryParams = [];

      if (staffId != null && staffId.isNotEmpty) {
        queryParams.add('staffId=$staffId');
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams.add('startDate=$startDate');
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams.add('endDate=$endDate');
      }
      if (date != null && date.isNotEmpty) {
        queryParams.add('date=$date');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      AppLogger.debug('ShiftsService | GET $url');
      final response = await _apiService.get(url);
      AppLogger.debug(
          'ShiftsService | attendance tracking status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        AppLogger.debug(
            'ShiftsService | attendance data type: ${data.runtimeType}');

        List<dynamic> records = [];
        if (data is List) {
          records = data;
        } else if (data is Map) {
          if (data.containsKey('records')) {
            records = data['records'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            records = data['data'] as List<dynamic>;
          }
        }

        AppLogger.debug(
            'ShiftsService | attendance records count: ${records.length}');
        for (var record in records) {
          AppLogger.debug(
              'ShiftsService | record: date=${record['date']}, actualStart=${record['actualStart']}, actualEnd=${record['actualEnd']}');
        }
        return records;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Ошибка получения данных: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception('Ошибка получения данных: ${e.message}');
    } catch (e) {
      AppLogger.error('ShiftsService | Exception: $e');
      throw Exception('Ошибка получения данных: $e');
    }
  }

  Future<void> checkIn(String shiftId,
      {double? latitude,
      double? longitude,
      String? status,
      Map<String, dynamic>? deviceMetadata}) async {
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
        data['status'] = status;
      }
      if (deviceMetadata != null) {
        data['deviceMetadata'] = deviceMetadata;
      }

      final response = await _apiService.post(
        ApiConstants.staffShiftCheckin(shiftId),
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage =
            'Ошибка отметки прихода. Код: ${response.statusCode}';
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

  Future<void> checkOut(String shiftId,
      {double? latitude,
      double? longitude,
      String? status,
      Map<String, dynamic>? deviceMetadata}) async {
    try {
      final data = <String, dynamic>{};
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      if (status != null) {
        data['status'] = status;
      }
      if (deviceMetadata != null) {
        data['deviceMetadata'] = deviceMetadata;
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
