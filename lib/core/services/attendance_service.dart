import '../constants/api_constants.dart';
import '../../models/attendance_model.dart';
import 'api_service.dart';
import 'dart:io';

class AttendanceService {
  final ApiService _apiService = ApiService();

  // Get all attendance records
  Future<List<Attendance>> getAllAttendance() async {
    try {
      final response = await _apiService.get(ApiConstants.attendanceEntries);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
 }

  // Get attendance by user ID
 Future<List<Attendance>> getAttendanceByUserId(String userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.attendanceEntries}?userId=$userId'
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Ошибка получения посещаемости: $e');
      return [];
    }
  }

  // Get attendance by date
  Future<List<Attendance>> getAttendanceByDate(String date) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.attendanceEntries}?date=$date'
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Ошибка получения посещаемости по дате: $e');
      return [];
    }
  }

  // Mark attendance (using clock-in endpoint)
  Future<Attendance> markAttendance(Attendance attendance) async {
    try {
      final response = await _apiService.post(
        ApiConstants.clockIn,
        data: attendance.toJson(),
      );
      if (response.statusCode == 201) {
        return Attendance.fromJson(response.data);
      }
      throw Exception('Ошибка отметки посещаемости');
    } catch (e) {
      throw Exception('Ошибка отметки посещаемости: $e');
    }
  }

  // Update attendance
  Future<Attendance> updateAttendance(String id, Attendance attendance) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.attendanceEntries}/$id',
        data: attendance.toJson(),
      );
      if (response.statusCode == 200) {
        return Attendance.fromJson(response.data);
      }
      throw Exception('Ошибка обновления посещаемости');
    } catch (e) {
      throw Exception('Ошибка обновления посещаемости: $e');
    }
  }

  // Delete attendance
  Future<bool> deleteAttendance(String id) async {
    try {
      final response = await _apiService.delete('${ApiConstants.attendanceEntries}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Ошибка удаления посещаемости: $e');
      return false;
    }
  }
}