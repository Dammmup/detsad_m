import '../constants/api_constants.dart';
import 'api_service.dart';
import 'dart:io';

class GroupsService {
  final ApiService _apiService = ApiService();

  // Get all groups
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    try {
      final response = await _apiService.get(ApiConstants.groups);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }

  // Get group by ID
  Future<Map<String, dynamic>?> getGroupById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.groups}/$id');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get groups by teacher ID
  Future<List<Map<String, dynamic>>> getGroupsByTeacherId(
      String teacherId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.groups}?teacherId=$teacherId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }
}