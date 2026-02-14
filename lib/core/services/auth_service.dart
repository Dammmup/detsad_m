import '../constants/api_constants.dart';
import '../../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'dart:io';
import '../utils/logger.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final user = User.fromJson(data['user']);

        await StorageService.ensureInitialized();
        await _storageService.saveToken(token);
        await _storageService.saveUser(user);

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      }

      return {
        'success': false,
        'message': response.data?['error'] ?? 'Login failed',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Нет подключения к интернету',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Неверный формат данных от сервера',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка подключения к серверу: ${e.toString()}',
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
      await StorageService.ensureInitialized();
      await _storageService.clearAll();
      return true;
    } catch (e) {
      await _storageService.clearAll();
      return false;
    }
  }

  Future<bool> validateToken() async {
    try {
      AppLogger.info('AuthService.validateToken | Validating with server...');
      final response = await _apiService.get(ApiConstants.validateToken);
      final isValid = response.statusCode == 200 && response.data['valid'] == true;
      AppLogger.info('AuthService.validateToken | Response: ${response.statusCode}, valid: ${response.data['valid']}, result: $isValid');
      return isValid;
    } catch (e) {
      AppLogger.error('AuthService.validateToken | Validation error: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConstants.currentUser);
      if (response.statusCode == 200) {
        final userData = response.data;
        final user = User.fromJson(userData);
        await StorageService.ensureInitialized();
        await _storageService.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    AppLogger.info('AuthService.isLoggedIn | Starting...');
    await StorageService.ensureInitialized();
    AppLogger.info('AuthService.isLoggedIn | Storage initialized');
    
    final token = await _storageService.getToken();
    AppLogger.info('AuthService.isLoggedIn | Token: ${token != null ? "EXISTS (${token.length} chars)" : "NULL"}');
    
    if (token == null) {
      AppLogger.warning('AuthService.isLoggedIn | No token found');
      return false;
    }
    
    final isValid = await validateToken();
    AppLogger.info('AuthService.isLoggedIn | Token validation result: $isValid');
    return isValid;
  }

  Future<User?> getStoredUser() async {
    await StorageService.ensureInitialized();
    return await _storageService.getUser();
  }

  Future<bool> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  }) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.users}/$userId',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (avatar != null) 'avatar': avatar,
        },
      );

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(response.data);
        await _storageService.saveUser(updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.users}/$userId/change-password',
        data: {'newPassword': newPassword},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerFCMToken(String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.subscribeFCM,
        data: {'token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unregisterFCMToken(String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.unsubscribeFCM,
        data: {'token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
