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
      //print('ChildrenService | GET /children | Статус: ${response.statusCode}');
      //print('ChildrenService | GET /children | Данные: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        if (data is List) {
          // Фильтруем только валидные объекты Child
          return data
              .where((json) => json is Map<String, dynamic> && json['fullName'] != null)
              .map((json) => Child.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data.containsKey('children')) {
          final childrenList = data['children'] as List<dynamic>;
          return childrenList
              .where((json) => json is Map<String, dynamic> && json['fullName'] != null)
              .map((json) => Child.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          //print('ChildrenService | Неподдерживаемый формат данных: $data');
          return [];
        }
      } else {
        //print('ChildrenService | Ошибка: ${response.statusCode} - ${response.data}');
        return [];
      }
    } on SocketException {
      //print('ChildrenService | Ошибка сети: Нет подключения к интернету');
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      //print('ChildrenService | Исключение: $e');
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

  // Get children by group ID
 Future<List<Child>> getChildrenByGroupId(String groupId) async {
    try {
      // childrenByGroup is a function, not a property - call it with groupId
      final url = ApiConstants.childrenByGroup(groupId);
      print('ChildrenService | GET $url');
      final response = await _apiService.get(url);
      print('ChildrenService | Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        print('ChildrenService | Data type: ${data.runtimeType}');
        if (data is List) {
          final children = data
              .where((json) => json is Map<String, dynamic> && json['fullName'] != null)
              .map((json) => Child.fromJson(json as Map<String, dynamic>))
              .toList();
          print('ChildrenService | Parsed ${children.length} children');
          return children;
        } else if (data is Map) {
          // Handle both 'children' and 'data' wrappers
          final dynamic childrenList = data['children'] ?? data['data'];
          if (childrenList is List<dynamic>) {
            final children = childrenList
                .where((json) => json is Map<String, dynamic> && json['fullName'] != null)
                .map((json) => Child.fromJson(json as Map<String, dynamic>))
                .toList();
            print('ChildrenService | Parsed ${children.length} children from wrapper');
            return children;
          }
        }
        return [];
      } else {
        print('ChildrenService | Error status: ${response.statusCode}');
        return [];
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      print('ChildrenService | Exception: $e');
      throw Exception('Ошибка получения данных: $e');
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
        throw Exception(
            'Некорректные данные. Проверьте правильность введенной информации');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для добавления ребенка');
      } else if (response.statusCode == 409) {
        throw Exception('Ребенок с такими данными уже существует');
      } else {
        throw Exception(
            'Ошибка создания ребенка. Код ошибки: ${response.statusCode}');
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
        throw Exception(
            'Некорректные данные. Проверьте правильность введенной информации');
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для обновления этого ребенка');
      } else if (response.statusCode == 404) {
        throw Exception('Ребенок не найден');
      } else {
        throw Exception(
            'Ошибка обновления ребенка. Код ошибки: ${response.statusCode}');
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
      final response = await _apiService.delete('${ApiConstants.children}/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Нет прав для удаления этого ребенка');
      } else if (response.statusCode == 404) {
        throw Exception('Ребенок не найден');
      } else {
        throw Exception(
            'Ошибка удаления ребенка. Код ошибки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка удаления ребенка: $e');
    }
 }
}
