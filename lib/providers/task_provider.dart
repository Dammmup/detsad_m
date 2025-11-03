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

  // Load tasks for current user
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

 // Load all tasks
  Future<void> loadAllTasks({String? assignedTo, String? status, String? category}) async {
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

  // Load overdue tasks
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

  // Toggle task status
  Future<void> toggleTaskStatus(String taskId, String userId) async {
    try {
      final updatedTask = await _taskService.toggleTaskStatus(taskId, userId);
      
      // Update the task in the local list
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

  // Refresh tasks
  Future<void> refreshTasks(String userId) async {
    await loadTasksForUser(userId);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}