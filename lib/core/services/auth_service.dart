import '../constants/api_constants.dart';
import '../../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'dart:io';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login
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

        // Ensure storage is initialized before saving
        await _storageService.init();
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

  // Logout
 Future<bool> logout() async {
    try {
      await _apiService.post(ApiConstants.logout);
      await _storageService.init();
      await _storageService.clearAll();
      return true;
    } catch (e) {
      // Clear local data even if API call fails
      await _storageService.clearAll();
      return false;
    }
  }

  // Validate Token
  Future<bool> validateToken() async {
    try {
      final response = await _apiService.get(ApiConstants.validateToken);
      return response.statusCode == 200 && response.data['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  // Get Current User
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConstants.currentUser);
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        await _storageService.init();
        await _storageService.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

 // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await _storageService.init();
    final token = await _storageService.getToken();
    if (token == null) return false;
    return await validateToken();
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    await _storageService.init();
    return await _storageService.getUser();
  }
}