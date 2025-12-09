import 'package:flutter/material.dart';
import '../core/services/shifts_service.dart';
import 'geolocation_provider.dart';

class ShiftsProvider with ChangeNotifier {
  final ShiftsService _shiftsService = ShiftsService();
  GeolocationProvider? _geolocationProvider;

  String _status = 'no_record'; // 'scheduled', 'in_progress', 'completed', 'no_record', 'error'
  String? _shiftId;
  bool _loading = false;
  String? _errorMessage;
  bool _notificationsScheduled = false;

  ShiftsProvider({GeolocationProvider? geolocationProvider})
      : _geolocationProvider = geolocationProvider;

  void setGeolocationProvider(GeolocationProvider geolocationProvider) {
    _geolocationProvider = geolocationProvider;
  }

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
      
      // Try to get shifts without filtering by staffId first (backend handles this)
      List<dynamic> shifts = await _shiftsService.getStaffShifts(
        staffId: userId,
        startDate: today,
        endDate: today,
      );

      // Also try without staffId if backend filters automatically
      if (shifts.isEmpty) {
        shifts = await _shiftsService.getStaffShifts(
          startDate: today,
          endDate: today,
        );
      }

      // Find shift for current user
      dynamic myShift;
      for (var shift in shifts) {
        // Check if this shift belongs to the current user
        // staffId can be a string ID or an object with _id
        String? shiftStaffId;
        if (shift['staffId'] is String) {
          shiftStaffId = shift['staffId'] as String;
        } else if (shift['staffId'] is Map) {
          shiftStaffId = shift['staffId']['_id']?.toString() ?? shift['staffId']['id']?.toString();
        }
        
        // Normalize IDs for comparison (remove any whitespace)
        String normalizedUserId = userId.trim();
        String? normalizedShiftStaffId = shiftStaffId?.trim();
        
        // Also check alternativeStaffId (for substitute staff)
        String? alternativeStaffId;
        if (shift['alternativeStaffId'] != null) {
          if (shift['alternativeStaffId'] is String) {
            alternativeStaffId = shift['alternativeStaffId'] as String;
          } else if (shift['alternativeStaffId'] is Map) {
            alternativeStaffId = shift['alternativeStaffId']['_id']?.toString() ?? shift['alternativeStaffId']['id']?.toString();
          }
        }
        String? normalizedAlternativeStaffId = alternativeStaffId?.trim();
        
        // Check if user is either the main staff or alternative staff for this shift
        if (normalizedShiftStaffId == normalizedUserId || normalizedAlternativeStaffId == normalizedUserId) {
          myShift = shift;
          break;
        }
      }

      if (myShift != null) {
        // Get shift status - handle both 'in_progress' and 'late' statuses
        String shiftStatus = myShift['status'] ?? 'scheduled';
        // If status is 'late', we still want to show it as 'in_progress' for UI purposes
        // because 'late' means the shift has started (they checked in)
        if (shiftStatus == 'late') {
          _status = 'in_progress';
        } else {
          _status = shiftStatus;
        }
        
        // Get shift ID - MongoDB uses _id, but API might return id as well
        _shiftId = myShift['_id']?.toString() ?? myShift['id']?.toString();
        
        // If shiftId is still null, try to get it from other possible fields
        if (_shiftId == null || _shiftId!.isEmpty) {
          _shiftId = myShift['_id']?.toString() ?? myShift['id']?.toString() ?? myShift['shiftId']?.toString();
        }
        
        // Validate that we have a valid shift ID
        if (_shiftId == null || _shiftId!.isEmpty) {
          _status = 'error';
          _errorMessage = 'Не удалось получить ID смены. Формат данных неверный.';
          _shiftId = null;
        } else {
          _errorMessage = null;
        }
      } else {
        _status = 'no_record';
        _shiftId = null;
        // Provide more helpful error message
        if (shifts.isEmpty) {
          _errorMessage = 'Смены на сегодня не найдены. Убедитесь, что смена запланирована на $today.';
        } else {
          _errorMessage = 'Не найдена смена на сегодня для текущего сотрудника. Найдено смен: ${shifts.length}.';
        }
      }
    } catch (e) {
      _status = 'error';
      _errorMessage = 'Ошибка при получении данных о смене: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Check in
  Future<void> checkIn(String userId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double? latitude;
      double? longitude;
      String? status;

      // Time check - determine if check-in is on-time or late
      // Time window: 7:00 AM to 8:00 AM by local time (Astana time)
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;
      
      // Check if current time is between 7:00 and 8:00 AM
      // If the check-in is made outside this window, mark as 'late'
      if (currentHour == 7 || (currentHour == 8 && currentMinute == 0)) {
        status = 'on_time';
      } else {
        status = 'late';
      }

      // Geofence check
      if (_geolocationProvider != null && _geolocationProvider!.enabled) {
        // Check if we have permissions but location is temporarily unavailable
        if (_geolocationProvider!.isLocationTemporarilyUnavailable) {
          // If GPS is temporarily unavailable but permissions are granted, we can still proceed
          // For now, we'll show a warning but not block the check-in
          // In a real scenario, you might want to save the check-in for later processing
          _errorMessage = 'GPS сигнал временно недоступен, отметка будет выполнена без геолокации.';
        } else if (!_geolocationProvider!.isPositionLoaded) {
          _errorMessage = 'Не удалось определить вашу геолокацию. Попробуйте еще раз.';
          _status = 'error';
          notifyListeners();
          return;
        } else if (!_geolocationProvider!.isWithinGeofence) {
          final distance = _geolocationProvider!.calculateDistance(
            _geolocationProvider!.currentPosition!.latitude,
            _geolocationProvider!.currentPosition!.longitude,
          );
          _errorMessage = 'Вы находитесь вне геозоны (${distance.toStringAsFixed(0)}м от офиса).';
          _status = 'error';
          notifyListeners();
          return;
        } else {
          latitude = _geolocationProvider!.currentPosition!.latitude;
          longitude = _geolocationProvider!.currentPosition!.longitude;
        }
      }

      // Ensure we have the latest shift status before checking in, but only if we don't have a shift yet
      if (_shiftId == null) {
        await fetchShiftStatus(userId);
      }

      if (_shiftId != null) {
        await _shiftsService.checkIn(_shiftId!, latitude: latitude, longitude: longitude, status: status);
        
        // Reload shift status from server to get the actual updated status
        await fetchShiftStatus(userId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Смена не найдена на сегодня. Возможно, смена не запланирована или данные о смене еще не загружены. Попробуйте обновить страницу.';
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
  Future<void> checkOut(String userId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double? latitude;
      double? longitude;
      String? status;

      // Time check - determine if check-out is on-time or early
      // For check-out, we can define appropriate time windows if needed
      // For now, we'll just pass a default status or implement specific logic
      // You can implement specific check-out time logic here if needed
      // For now, default to 'on_time' but this could be enhanced based on requirements
      status = 'on_time'; // Default status for check-out

      // Geofence check
      if (_geolocationProvider != null && _geolocationProvider!.enabled) {
        // Check if we have permissions but location is temporarily unavailable
        if (_geolocationProvider!.isLocationTemporarilyUnavailable) {
          // If GPS is temporarily unavailable but permissions are granted, we can still proceed
          // For now, we'll show a warning but not block the check-out
          // In a real scenario, you might want to save the check-out for later processing
          _errorMessage = 'GPS сигнал временно недоступен, отметка будет выполнена без геолокации.';
        } else if (!_geolocationProvider!.isPositionLoaded) {
          _errorMessage = 'Не удалось определить вашу геолокацию. Попробуйте еще раз.';
          _status = 'error';
          notifyListeners();
          return;
        } else if (!_geolocationProvider!.isWithinGeofence) {
          final distance = _geolocationProvider!.calculateDistance(
            _geolocationProvider!.currentPosition!.latitude,
            _geolocationProvider!.currentPosition!.longitude,
          );
          _errorMessage = 'Вы находитесь вне геозоны (${distance.toStringAsFixed(0)}м от офиса).';
          _status = 'error';
          notifyListeners();
          return;
        } else {
          latitude = _geolocationProvider!.currentPosition!.latitude;
          longitude = _geolocationProvider!.currentPosition!.longitude;
        }
      }

      // Ensure we have the latest shift status before checking out, but only if we don't have a shift yet
      if (_shiftId == null) {
        await fetchShiftStatus(userId);
      }

      if (_shiftId != null) {
        await _shiftsService.checkOut(_shiftId!, latitude: latitude, longitude: longitude, status: status);
        
        // Reload shift status from server to get the actual updated status
        await fetchShiftStatus(userId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Смена не найдена на сегодня. Возможно, смена не запланирована или данные о смене еще не загружены. Попробуйте обновить страницу.';
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