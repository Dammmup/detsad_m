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

  /// Обновление смены (изменение статуса, заметок и т.д.)
  Future<Map<String, dynamic>?> updateShift(
      String shiftId, Map<String, dynamic> data) async {
    try {
      if (shiftId.isEmpty) {
        throw Exception('ID смены не указан');
      }

      final response = await _apiService.put(
        '${ApiConstants.staffShifts}/$shiftId',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return null;
      } else {
        String errorMessage =
            'Ошибка обновления смены. Код: ${response.statusCode}';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'].toString();
        } else if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'].toString();
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      String errorMessage = 'Ошибка обновления смены';
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
      throw Exception('Ошибка обновления смены: $e');
    }
  }

  /// Массовое создание смен (для назначения графика 5/2)
  Future<Map<String, dynamic>> bulkCreateShifts(
      List<Map<String, dynamic>> shifts) async {
    try {
      final response = await _apiService.post(
        ApiConstants.staffShiftsBulk,
        data: {'shifts': shifts},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'success': shifts.length};
      } else {
        throw Exception('Ошибка массового создания смен: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Ошибка массового создания смен');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка массового создания смен: $e');
    }
  }

  /// Массовое обновление статусов смен по фильтрам
  Future<void> bulkUpdateStatus({
    required String startDate,
    required String endDate,
    required String status,
    String? staffId,
  }) async {
    try {
      final data = <String, dynamic>{
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
      };
      if (staffId != null && staffId.isNotEmpty) {
        data['staffId'] = staffId;
      }

      final response = await _apiService.post(
        ApiConstants.staffShiftsBulkUpdateStatus,
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка массового обновления статусов: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Ошибка массового обновления статусов');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка массового обновления статусов: $e');
    }
  }

  /// Удаление смены
  Future<void> deleteShift(String shiftId) async {
    try {
      if (shiftId.isEmpty) throw Exception('ID смены не указан');

      final response = await _apiService.delete(
        ApiConstants.staffShiftById(shiftId),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Ошибка удаления смены: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Ошибка удаления смены');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка удаления смены: $e');
    }
  }

  /// Получить все смены (для админа — без фильтра по staffId)
  Future<List<dynamic>> getAllStaffShifts({
    required String startDate,
    required String endDate,
  }) async {
    try {
      String url = '${ApiConstants.staffShifts}?startDate=$startDate&endDate=$endDate';
      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is List) return data;
        if (data is Map && data.containsKey('shifts')) {
          return data['shifts'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Ошибка загрузки смен: $e');
    }
  }

  /// Массовое обновление записей учета времени
  Future<void> bulkUpdateAttendanceRecords({
    required List<String> ids,
    String? status,
    String? timeStart,
    String? timeEnd,
    String? notes,
  }) async {
    try {
      if (ids.isEmpty) return;

      final data = <String, dynamic>{
        'ids': ids,
      };
      if (status != null && status.isNotEmpty) data['status'] = status;
      if (timeStart != null && timeStart.isNotEmpty) data['timeStart'] = timeStart;
      if (timeEnd != null && timeEnd.isNotEmpty) data['timeEnd'] = timeEnd;
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;

      final response = await _apiService.post(
        ApiConstants.staffAttendanceTrackingBulkUpdate,
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Ошибка массового обновления записей: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['error'] ?? 'Ошибка массового обновления записей');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ошибка массового обновления записей: $e');
    }
  }
}
