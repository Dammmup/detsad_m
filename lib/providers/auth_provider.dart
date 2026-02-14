import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';
import '../core/services/storage_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider | Initializing session...');
      await StorageService.ensureInitialized();
      await StorageService().init();

      _isLoggedIn = await _authService.isLoggedIn();
      AppLogger.info('AuthProvider | Session active: $_isLoggedIn');

      if (_isLoggedIn) {
        _user = await _authService.getStoredUser();
        AppLogger.info('AuthProvider | Restored user: ${_user?.fullName}');

        final updatedUser = await _authService.getCurrentUser();
        if (updatedUser != null) {
          _user = updatedUser;
          AppLogger.info('AuthProvider | User info refreshed from server');
        }

        _registerFCM();
      }
    } catch (e) {
      AppLogger.error('AuthProvider | Session recovery error: $e');
      _errorMessage = e.toString();
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider | Attempting login for $phone');
      await StorageService.ensureInitialized();
      await StorageService().init();

      final result = await _authService.login(phone, password);

      if (result['success'] == true) {
        _user = result['user'];
        _isLoggedIn = true;
        _isLoading = false;
        AppLogger.info(
            'AuthProvider | Login successful for ${_user?.fullName}');

        _registerFCM();

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Ошибка входа';
        AppLogger.warning('AuthProvider | Login failed: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      AppLogger.error('AuthProvider | Login exception: $e');
      _errorMessage = 'Ошибка подключения к серверу';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _registerFCM() async {
    try {
      final token = await _notificationService.getFCMToken();
      if (token != null) {
        AppLogger.debug('Registering FCM token: $token');
        await _authService.registerFCMToken(token);
      }
    } catch (e) {
      AppLogger.error('Failed to register FCM token: $e');
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to unregister FCM token before logout
      final token = await _notificationService.getFCMToken();
      if (token != null) {
        await _authService.unregisterFCMToken(token);
      }

      await _authService.logout();
      _user = null;
      _isLoggedIn = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final updatedUser = await _authService.getCurrentUser();
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
