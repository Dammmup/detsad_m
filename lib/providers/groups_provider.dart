import 'package:flutter/material.dart';
import '../core/services/groups_service.dart';

class GroupsProvider with ChangeNotifier {
  final GroupsService _groupsService = GroupsService();
  
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all groups
  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _groupsService.getAllGroups();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load groups by teacher ID
  Future<void> loadGroupsByTeacherId(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _groupsService.getGroupsByTeacherId(teacherId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 // Get group by ID
  Map<String, dynamic>? getGroupById(String id) {
    return _groups.firstWhere((group) => group['_id'] == id || group['id'] == id, orElse: () => _groups.first);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}