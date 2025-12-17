import '../constants/api_constants.dart';
import '../../models/group_model.dart';
import 'api_service.dart';
import '../utils/logger.dart';
import 'dart:io';

class GroupsService {
  final ApiService _apiService = ApiService();

  Future<List<Group>> getAllGroups() async {
    try {
      final response = await _apiService.get(ApiConstants.groups);
      AppLogger.debug(
          'GroupsService | GET ${ApiConstants.groups} | Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        AppLogger.debug('GroupsService | Received ${data.length} groups');
        for (var json in data) {
          AppLogger.debug(
              'GroupsService | Raw group JSON: name=${json['name']}, teacherId=${json['teacherId']}, teacher=${json['teacher']}');
        }
        return data.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      AppLogger.error('GroupsService | Error: $e');
      throw Exception('Ошибка получения данных: $e');
    }
  }

  Future<Group?> getGroupById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.groups}/$id');
      if (response.statusCode == 200) {
        return Group.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Group>> getGroupsByTeacherId(String teacherId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.groups}?teacher=$teacherId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Group.fromJson(json)).toList();
        } else if (data is Map) {
          final dynamic groupsList = data['groups'] ?? data['data'];
          if (groupsList is List<dynamic>) {
            return groupsList.map((j) => Group.fromJson(j)).toList();
          }
        }
      }

      final fallback =
          await _apiService.get('${ApiConstants.groups}?teacher=$teacherId');

      if (fallback.statusCode == 200 && fallback.data is List) {
        return (fallback.data as List)
            .map((json) => Group.fromJson(json))
            .toList();
      }

      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }
}
