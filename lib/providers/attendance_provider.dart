import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../core/services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Attendance> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all attendance records
 Future<void> loadAttendance() async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceRecords = await _attendanceService.getAllAttendance();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load attendance by user ID
 Future<void> loadAttendanceByUserId(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceRecords = await _attendanceService.getAttendanceByUserId(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark attendance
  Future<void> markAttendance(Attendance attendance) async {
    try {
      final newAttendance = await _attendanceService.markAttendance(attendance);
      _attendanceRecords.add(newAttendance);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update attendance
  Future<void> updateAttendance(String id, Attendance updatedAttendance) async {
    try {
      final updated = await _attendanceService.updateAttendance(id, updatedAttendance);
      final index = _attendanceRecords.indexWhere((attendance) => attendance.id == id);
      if (index != -1) {
        _attendanceRecords[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete attendance
  Future<void> deleteAttendance(String id) async {
    try {
      final success = await _attendanceService.deleteAttendance(id);
      if (success) {
        _attendanceRecords.removeWhere((attendance) => attendance.id == id);
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