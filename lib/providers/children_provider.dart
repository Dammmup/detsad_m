import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../core/services/children_service.dart';

class ChildrenProvider with ChangeNotifier {
  final ChildrenService _childrenService = ChildrenService();
  
  List<Child> _children = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Child> get children => _children;
 bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all children
  Future<void> loadChildren() async {
    _isLoading = true;
    notifyListeners();

    try {
      _children = await _childrenService.getAllChildren();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get child by ID
  Child? getChildById(String id) {
    return _children.firstWhere((child) => child.id == id, orElse: () => _children.first);
  }

  // Add a new child
  Future<void> addChild(Child child) async {
    try {
      final newChild = await _childrenService.createChild(child);
      _children.add(newChild);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update a child
  Future<void> updateChild(String id, Child updatedChild) async {
    try {
      final updated = await _childrenService.updateChild(id, updatedChild);
      final index = _children.indexWhere((child) => child.id == id);
      if (index != -1) {
        _children[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete a child
 Future<void> deleteChild(String id) async {
    try {
      final success = await _childrenService.deleteChild(id);
      if (success) {
        _children.removeWhere((child) => child.id == id);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}