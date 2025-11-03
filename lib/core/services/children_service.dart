import '../constants/api_constants.dart';
import '../../models/child_model.dart';
import 'api_service.dart';
import 'dart:io';

class ChildrenService {
  final ApiService _apiService = ApiService();

  // Get all children
  Future<List<Child>> getAllChildren() async {
    try {
      final response = await _apiService.get(ApiConstants.children);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Child.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
 }

  // Get child by ID
  Future<Child?> getChildById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.children}/$id');
      if (response.statusCode == 200) {
        return Child.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Ошибка получения ребенка: $e');
      return null;
    }
  }

 // Create child
 Future<Child> createChild(Child child) async {
    try {
      final response = await _apiService.post(
        ApiConstants.children,
        data: child.toJson(),
      );
      if (response.statusCode == 201) {
        return Child.fromJson(response.data);
      }
      throw Exception('Ошибка создания ребенка');
    } catch (e) {
      throw Exception('Ошибка создания ребенка: $e');
    }
 }

  // Update child
  Future<Child> updateChild(String id, Child child) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.children}/$id',
        data: child.toJson(),
      );
      if (response.statusCode == 200) {
        return Child.fromJson(response.data);
      }
      throw Exception('Ошибка обновления ребенка');
    } catch (e) {
      throw Exception('Ошибка обновления ребенка: $e');
    }
  }

  // Delete child
  Future<bool> deleteChild(String id) async {
    try {
      final response = await _apiService.delete('${ApiConstants.children}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Ошибка удаления ребенка: $e');
      return false;
    }
  }
}