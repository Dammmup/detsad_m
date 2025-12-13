import '../constants/api_constants.dart';
import '../../models/group_model.dart';
import 'api_service.dart';
import 'dart:io';

class GroupsService {
  final ApiService _apiService = ApiService();

  // Get all groups
  Future<List<Group>> getAllGroups() async {
    try {
      final response = await _apiService.get(ApiConstants.groups);
      print('GroupsService | GET ${ApiConstants.groups} | Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('GroupsService | Received ${data.length} groups');
        for (var json in data) {
          print('GroupsService | Raw group JSON: name=${json['name']}, teacherId=${json['teacherId']}, teacher=${json['teacher']}');
        }
        return data.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      print('GroupsService | Error: $e');
      throw Exception('Ошибка получения данных: $e');
    }
  }


  // Get group by ID
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

  // Get groups by teacher ID
  // groups_service.dart
  Future<List<Group>> getGroupsByTeacherId(String teacherId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.groups}?teacher=$teacherId');
      // debug:
      // print('GroupsService | GET groups?teacherId= -> status ${response.statusCode} data: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Group.fromJson(json)).toList();
        } else if (data is Map) {
          final dynamic groupsList = data['groups'] ?? data['data'];
          if (groupsList is List<dynamic>) {
            return groupsList
                .map((j) => Group.fromJson(j))
                .toList();
          }
        }
      }

      // fallback: try with 'teacher' param if first returned nothing
      final fallback =
          await _apiService.get('${ApiConstants.groups}?teacher=$teacherId');
      // print('GroupsService | fallback teacher= -> status ${fallback.statusCode} data: ${fallback.data}');
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
