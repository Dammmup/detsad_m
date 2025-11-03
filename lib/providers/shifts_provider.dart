import 'package:flutter/material.dart';
import '../core/services/shifts_service.dart';

class ShiftsProvider with ChangeNotifier {
  final ShiftsService _shiftsService = ShiftsService();
  
  String _status = 'no_record'; // 'scheduled', 'in_progress', 'completed', 'no_record', 'error'
  bool _loading = false;
  String? _errorMessage;
  bool _notificationsScheduled = false;

  String get status => _status;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get areNotificationsScheduled => _notificationsScheduled;

  // Update shift status
  void updateStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // Fetch shift status for current user
  Future<void> fetchShiftStatus(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      List<dynamic> shifts = await _shiftsService.getStaffShifts(
        staffId: userId,
        startDate: today,
        endDate: today,
      );

      // Find shift for current user
      dynamic myShift;
      for (var shift in shifts) {
        if (shift['staffId'] == userId || 
            (shift['staffId'] is Map && shift['staffId']['_id'] == userId)) {
          myShift = shift;
          break;
        }
      }

      if (myShift != null) {
        _status = myShift['status'] ?? 'scheduled';
      } else {
        _status = 'no_record';
      }
      _errorMessage = null;
    } catch (e) {
      _status = 'error';
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

 // Check in
 Future<void> checkIn(String userId, {double? latitude, double? longitude}) async {
    _loading = true;
    notifyListeners();

    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      List<dynamic> shifts = await _shiftsService.getStaffShifts(
        staffId: userId,
        startDate: today,
        endDate: today,
      );

      // Find shift for current user
      dynamic myShift;
      for (var shift in shifts) {
        if (shift['staffId'] == userId ||
            (shift['staffId'] is Map && shift['staffId']['_id'] == userId)) {
          myShift = shift;
          break;
        }
      }

      if (myShift != null && myShift['id'] != null) {
        await _shiftsService.checkIn(myShift['id'], latitude: latitude, longitude: longitude);
        _status = 'in_progress';
        _errorMessage = null;
      } else {
        _errorMessage = 'Смена не найдена на сегодня';
        _status = 'error';
      }
    } catch (e) {
      _status = 'error';
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Check out
  Future<void> checkOut(String userId, {double? latitude, double? longitude}) async {
    _loading = true;
    notifyListeners();

    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      List<dynamic> shifts = await _shiftsService.getStaffShifts(
        staffId: userId,
        startDate: today,
        endDate: today,
      );

      // Find shift for current user
      dynamic myShift;
      for (var shift in shifts) {
        if (shift['staffId'] == userId ||
            (shift['staffId'] is Map && shift['staffId']['_id'] == userId)) {
          myShift = shift;
          break;
        }
      }

      if (myShift != null && myShift['id'] != null) {
        await _shiftsService.checkOut(myShift['id'], latitude: latitude, longitude: longitude);
        _status = 'completed';
        _errorMessage = null;
      } else {
        _errorMessage = 'Смена не найдена на сегодня';
        _status = 'error';
      }
    } catch (e) {
      _status = 'error';
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
 // Метод для установки флага, что уведомления запланированы
  void setNotificationsScheduled() {
    _notificationsScheduled = true;
    notifyListeners();
  }
}