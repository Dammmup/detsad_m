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
      } else if (response.statusCode == 404) {
        throw Exception('Ребенок не найден');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для просмотра этого ребенка');
      }
      return null;
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных ребенка: $e');
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
      } else if (response.statusCode == 400) {
        throw Exception('Некорректные данные. Проверьте правильность введенной информации');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для добавления ребенка');
      } else if (response.statusCode == 409) {
        throw Exception('Ребенок с такими данными уже существует');
      } else {
        throw Exception('Ошибка создания ребенка. Код ошибки: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Нет подключения к интернету');
      } else {
        throw Exception('Ошибка создания ребенка: $e');
      }
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
      } else if (response.statusCode == 400) {
        throw Exception('Некорректные данные. Проверьте правильность введенной информации');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для обновления этого ребенка');
      } else if (response.statusCode == 404) {
        throw Exception('Ребенок не найден');
      } else {
        throw Exception('Ошибка обновления ребенка. Код ошибки: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Нет подключения к интернету');
      } else {
        throw Exception('Ошибка обновления ребенка: $e');
      }
    }
 }

  // Delete child
  Future<bool> deleteChild(String id) async {
    try {
      final response =
          await _apiService.delete('${ApiConstants.children}/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для удаления этого ребенка');
      } else if (response.statusCode == 404) {
        throw Exception('Ребенок не найден');
      } else {
        throw Exception('Ошибка удаления ребенка. Код ошибки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка удаления ребенка: $e');
    }
  }
}