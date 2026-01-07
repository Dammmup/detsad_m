import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/services/shifts_service.dart';
import 'geolocation_provider.dart';

class ShiftsProvider with ChangeNotifier {
  final ShiftsService _shiftsService = ShiftsService();
  GeolocationProvider? _geolocationProvider;

  String _status = 'no_record';
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

  void updateStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<void> fetchShiftStatus(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      final almaty = tz.getLocation('Asia/Almaty');
      final nowAlmaty = tz.TZDateTime.now(almaty);
      String today = nowAlmaty.toIso8601String().split('T')[0];

      List<dynamic> shifts = await _shiftsService.getStaffShifts(
        staffId: userId,
        startDate: today,
        endDate: today,
      );

      dynamic myShift;
      for (var shift in shifts) {
        String? shiftStaffId;
        if (shift['staffId'] is String) {
          shiftStaffId = shift['staffId'] as String;
        } else if (shift['staffId'] is Map) {
          shiftStaffId = shift['staffId']['_id']?.toString() ??
              shift['staffId']['id']?.toString();
        }

        String normalizedUserId = userId.trim();
        String? normalizedShiftStaffId = shiftStaffId?.trim();

        String? alternativeStaffId;
        if (shift['alternativeStaffId'] != null) {
          if (shift['alternativeStaffId'] is String) {
            alternativeStaffId = shift['alternativeStaffId'] as String;
          } else if (shift['alternativeStaffId'] is Map) {
            alternativeStaffId =
                shift['alternativeStaffId']['_id']?.toString() ??
                    shift['alternativeStaffId']['id']?.toString();
          }
        }
        String? normalizedAlternativeStaffId = alternativeStaffId?.trim();

        if (normalizedShiftStaffId == normalizedUserId ||
            normalizedAlternativeStaffId == normalizedUserId) {
          myShift = shift;
          break;
        }
      }

      if (myShift != null) {
        String shiftStatus = myShift['status'] ?? 'scheduled';

        if (shiftStatus == 'late') {
          _status = 'in_progress';
        } else {
          _status = shiftStatus;
        }

        _shiftId = myShift['_id']?.toString() ?? myShift['id']?.toString();

        if (_shiftId == null || _shiftId!.isEmpty) {
          _shiftId = myShift['_id']?.toString() ??
              myShift['id']?.toString() ??
              myShift['shiftId']?.toString();
        }

        if (_shiftId == null || _shiftId!.isEmpty) {
          _status = 'error';
          _errorMessage =
              'Не удалось получить ID смены. Формат данных неверный.';
          _shiftId = null;
        } else {
          _errorMessage = null;
        }
      } else {
        _status = 'no_record';
        _shiftId = null;

        if (shifts.isEmpty) {
          _errorMessage =
              'Смены на сегодня не найдены. Убедитесь, что смена запланирована на $today.';
        } else {
          _errorMessage =
              'Не найдена смена на сегодня для текущего сотрудника. Найдено смен: ${shifts.length}.';
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

  Future<void> checkIn(String userId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double? latitude;
      double? longitude;

      if (_geolocationProvider != null && _geolocationProvider!.enabled) {
        if (_geolocationProvider!.isLocationTemporarilyUnavailable) {
          _errorMessage =
              'GPS сигнал временно недоступен, отметка будет выполнена без геолокации.';
        } else if (!_geolocationProvider!.isPositionLoaded) {
          _errorMessage =
              'Не удалось определить вашу геолокацию. Попробуйте еще раз.';
          _status = 'error';
          notifyListeners();
          return;
        } else if (!_geolocationProvider!.isWithinGeofence) {
          final distance = _geolocationProvider!.calculateDistance(
            _geolocationProvider!.currentPosition!.latitude,
            _geolocationProvider!.currentPosition!.longitude,
          );
          _errorMessage =
              'Вы находитесь вне геозоны (${distance.toStringAsFixed(0)}м от офиса).';
          _status = 'error';
          notifyListeners();
          return;
        } else {
          latitude = _geolocationProvider!.currentPosition!.latitude;
          longitude = _geolocationProvider!.currentPosition!.longitude;
        }
      }

      if (_shiftId == null) {
        await fetchShiftStatus(userId);
      }

      if (_shiftId != null) {
        // Backend handles status (late/on_time) based on actual shift settings
        await _shiftsService.checkIn(_shiftId!,
            latitude: latitude, longitude: longitude);

        await fetchShiftStatus(userId);
        _errorMessage = null;
      } else {
        _errorMessage =
            'Смена не найдена на сегодня. Возможно, смена не запланирована или данные о смене еще не загружены. Попробуйте обновить страницу.';
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

  Future<void> checkOut(String userId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double? latitude;
      double? longitude;

      if (_geolocationProvider != null && _geolocationProvider!.enabled) {
        if (_geolocationProvider!.isLocationTemporarilyUnavailable) {
          _errorMessage =
              'GPS сигнал временно недоступен, отметка будет выполнена без геолокации.';
        } else if (!_geolocationProvider!.isPositionLoaded) {
          _errorMessage =
              'Не удалось определить вашу геолокацию. Попробуйте еще раз.';
          _status = 'error';
          notifyListeners();
          return;
        } else if (!_geolocationProvider!.isWithinGeofence) {
          final distance = _geolocationProvider!.calculateDistance(
            _geolocationProvider!.currentPosition!.latitude,
            _geolocationProvider!.currentPosition!.longitude,
          );
          _errorMessage =
              'Вы находитесь вне геозоны (${distance.toStringAsFixed(0)}м от офиса).';
          _status = 'error';
          notifyListeners();
          return;
        } else {
          latitude = _geolocationProvider!.currentPosition!.latitude;
          longitude = _geolocationProvider!.currentPosition!.longitude;
        }
      }

      if (_shiftId == null) {
        await fetchShiftStatus(userId);
      }

      if (_shiftId != null) {
        await _shiftsService.checkOut(_shiftId!,
            latitude: latitude, longitude: longitude);

        await fetchShiftStatus(userId);
        _errorMessage = null;
      } else {
        _errorMessage =
            'Смена не найдена на сегодня. Возможно, смена не запланирована или данные о смене еще не загружены. Попробуйте обновить страницу.';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setNotificationsScheduled() {
    _notificationsScheduled = true;
    notifyListeners();
  }
}
