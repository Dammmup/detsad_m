import 'package:flutter/material.dart';
import '../core/services/task_service.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTasksForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasksByUser(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllTasks(
      {String? assignedTo, String? status, String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getAllTasks(
        assignedTo: assignedTo,
        status: status,
        category: category,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverdueTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getOverdueTasks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskStatus(String taskId, String userId) async {
    try {
      final updatedTask = await _taskService.toggleTaskStatus(taskId, userId);

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshTasks(String userId) async {
    await loadTasksForUser(userId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
