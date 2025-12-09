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
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
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
  Future<List<Group>> getGroupsByTeacherId(
      String teacherId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.groups}?teacherId=$teacherId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Group.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }
}