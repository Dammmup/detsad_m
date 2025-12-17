import '../constants/api_constants.dart';
import '../../models/attendance_model.dart';
import '../../models/attendance_record_model.dart';
import '../../models/child_model.dart';
import 'api_service.dart';
import 'children_service.dart';
import 'dart:io';

class AttendanceService {
  final ApiService _apiService = ApiService();

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

  Future<List<Attendance>> getAttendanceByUserId(String userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.attendanceEntries}?userId=$userId',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Attendance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.childAttendance}?date=$date',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Attendance.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Ошибка получения данных: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(String date) async {
    try {
      final attendanceData = await getAttendanceByDate(date);
      if (attendanceData.isEmpty) {
        return [];
      }

      final childrenService = ChildrenService();
      final uniqueChildIds = attendanceData
          .where((att) => att.childId != null)
          .map((att) => att.childId!)
          .toSet();

      final childrenList = <Child>[];
      for (final childId in uniqueChildIds) {
        try {
          final child = await childrenService.getChildById(childId);
          if (child != null) {
            childrenList.add(child);
          }
        } catch (e) {}
      }

      final childrenMap = {for (var child in childrenList) child.id: child};

      final records = attendanceData
          .map((att) {
            final child = childrenMap[att.childId];
            if (child != null) {
              return AttendanceRecord(attendance: att, child: child);
            }
            return null;
          })
          .whereType<AttendanceRecord>()
          .toList();

      return records;
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      throw Exception('Ошибка загрузки записей посещаемости: $e');
    }
  }

  Future<void> markAttendanceBulk(List<Attendance> attendances,
      {required String groupId}) async {
    try {
      final records = attendances.map((a) {
        final json = a.toJson();

        if (!json.containsKey('childId') ||
            json['childId'] == null ||
            json['childId'].toString().isEmpty) {
          if (json.containsKey('userId') &&
              json['userId'] != null &&
              json['userId'].toString().isNotEmpty) {
            json['childId'] = json['userId'];
          }
        }

        json.remove('userId');

        json.remove('_id');
        json.remove('createdAt');
        json.remove('updatedAt');

        if (json['checkIn'] == null || json['checkIn'].toString().isEmpty) {
          json.remove('checkIn');
        }
        if (json['checkOut'] == null || json['checkOut'].toString().isEmpty) {
          json.remove('checkOut');
        }
        return json;
      }).toList();

      final response = await _apiService.post(
        ApiConstants.childAttendanceBulk,
        data: {
          'records': records,
          'groupId': groupId,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage =
            'Ошибка отметки посещаемости. Код ошибки: ${response.statusCode}';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'].toString();
        } else if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'].toString();
        }
        throw Exception(errorMessage);
      }

      if (response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['errors'] != null &&
            (responseData['errors'] as List).isNotEmpty) {
          final errors = responseData['errors'] as List;
          final errorMessages = errors.map((e) {
            if (e is Map && e['error'] != null) {
              return e['error'].toString();
            }
            return e.toString();
          }).toList();
          throw Exception(
              'Ошибки при отметке посещаемости: ${errorMessages.join('; ')}');
        }

        if (responseData['errorCount'] != null &&
            (responseData['errorCount'] as int) > 0 &&
            (responseData['success'] == null ||
                (responseData['success'] as int) == 0)) {
          throw Exception(
              'Не удалось добавить посещаемость. Проверьте время, сотрудника и выбранных детей');
        }
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка отметки посещаемости: ${e.toString()}');
    }
  }

  Future<Attendance> markAttendance(Attendance attendance) async {
    try {
      final response = await _apiService.post(
        ApiConstants.childAttendance,
        data: attendance.toJson(),
      );
      if (response.statusCode == 201) {
        return Attendance.fromJson(response.data);
      } else if (response.statusCode == 400) {
        throw Exception('Некорректные данные для отметки посещаемости');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для отметки посещаемости');
      } else if (response.statusCode == 423) {
        throw Exception(
            'Время для отметки посещаемости еще не наступило или уже истекло');
      } else {
        throw Exception(
            'Ошибка отметки посещаемости. Код ошибки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка отметки посещаемости: $e');
    }
  }

  Future<Attendance> updateAttendance(String id, Attendance attendance) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.attendanceEntries}/$id',
        data: attendance.toJson(),
      );
      if (response.statusCode == 200) {
        return Attendance.fromJson(response.data);
      } else if (response.statusCode == 400) {
        throw Exception('Некорректные данные для обновления посещаемости');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для обновления посещаемости');
      } else if (response.statusCode == 404) {
        throw Exception('Запись посещаемости не найдена');
      } else {
        throw Exception(
            'Ошибка обновления посещаемости. Код ошибки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка обновления посещаемости: $e');
    }
  }

  Future<bool> deleteAttendance(String id) async {
    try {
      final response =
          await _apiService.delete('${ApiConstants.attendanceEntries}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
