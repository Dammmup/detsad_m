import '../constants/api_constants.dart';
import '../../models/task_model.dart';
import 'api_service.dart';
import 'dart:io';

class TaskService {
  final ApiService _apiService = ApiService();

  Future<List<Task>> getAllTasks(
      {String? assignedTo, String? status, String? category}) async {
    try {
      String url = ApiConstants.taskList;
      List<String> queryParams = [];

      if (assignedTo != null) queryParams.add('assignedTo=$assignedTo');
      if (status != null) queryParams.add('status=$status');
      if (category != null) queryParams.add('category=$category');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception('Ошибка получения задач: Некорректный формат данных');
      }
      throw Exception('Ошибка получения задач: $e');
    }
  }

  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.taskList}/user/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception(
            'Ошибка получения задач пользователя: Некорректный формат данных');
      }
      throw Exception('Ошибка получения задач пользователя: $e');
    }
  }

  Future<List<Task>> getOverdueTasks() async {
    try {
      final response = await _apiService.get(ApiConstants.taskListOverdue);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception(
            'Ошибка получения просроченных задач: Некорректный формат данных');
      }
      throw Exception('Ошибка получения просроченных задач: $e');
    }
  }

  Future<Task> getTaskById(String taskId) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.taskList}/$taskId');
      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      }
      throw Exception('Задача не найдена');
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception('Ошибка получения задачи: Некорректный формат данных');
      }
      throw Exception('Ошибка получения задачи: $e');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _apiService.post(
        ApiConstants.taskList,
        data: task.toJson(),
      );
      if (response.statusCode == 201) {
        return Task.fromJson(response.data);
      }
      throw Exception('Ошибка создания задачи');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception('Ошибка создания задачи: Некорректный формат данных');
      }
      throw Exception('Ошибка создания задачи: $e');
    }
  }

  Future<Task> updateTask(String taskId, Task task) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.taskList}/$taskId',
        data: task.toJson(),
      );
      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      }
      throw Exception('Ошибка обновления задачи');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception('Ошибка обновления задачи: Некорректный формат данных');
      }
      throw Exception('Ошибка обновления задачи: $e');
    }
  }

  Future<Task> toggleTaskStatus(String taskId, String userId) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.taskListToggle(taskId),
        data: {'userId': userId},
      );
      if (response.statusCode == 200) {
        return Task.fromJson(response.data);
      }
      throw Exception('Ошибка переключения статуса задачи');
    } catch (e) {
      if (e is TypeError || e.toString().contains('type')) {
        throw Exception(
            'Ошибка переключения статуса задачи: Некорректный формат данных');
      }
      throw Exception('Ошибка переключения статуса задачи: $e');
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response =
          await _apiService.delete('${ApiConstants.taskList}/$taskId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
