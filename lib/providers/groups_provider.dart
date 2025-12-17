import 'package:flutter/material.dart';
import '../core/services/groups_service.dart';
import '../models/group_model.dart';

class GroupsProvider with ChangeNotifier {
  final GroupsService _groupsService = GroupsService();

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadGroups() async {
    reset();
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _groupsService.getAllGroups();
      print('GroupsProvider | Loaded ${_groups.length} groups');
      for (var group in _groups) {
        print(
            'GroupsProvider | Group: ${group.name}, teacher: ${group.teacher}, id: ${group.id}');
      }
      _errorMessage = null;
      _hasLoaded = true;
    } catch (e) {
      print('GroupsProvider | Error loading groups: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupsByTeacherId(String teacherId) async {
    reset();
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _groupsService.getGroupsByTeacherId(teacherId);
      _errorMessage = null;
      _hasLoaded = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Group? getGroupById(String id) {
    try {
      String processedId = id;
      if (id.contains('\$oid')) {
        processedId =
            id.split('\$oid:').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      } else if (id.contains('ObjectId(')) {
        processedId = id.split('ObjectId(').last.split(')')[0];
      }
      return _groups.firstWhere((group) => group.id == processedId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _groups = [];
    _isLoading = false;
    _errorMessage = null;
    _hasLoaded = false;
    notifyListeners();
  }
}
