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
    _autoInitialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService().init();
      _isLoggedIn = await _authService.isLoggedIn();

      if (_isLoggedIn) {
        _user = await _authService.getStoredUser();

        final updatedUser = await _authService.getCurrentUser();
        if (updatedUser != null) {
          _user = updatedUser;
        }

        // Register FCM if logged in
        _registerFCM();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _autoInitialize() async {}

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(phone, password);

      if (result['success'] == true) {
        _user = result['user'];
        _isLoggedIn = true;
        _isLoading = false;

        // Register FCM after login
        _registerFCM();

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Ошибка входа';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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
