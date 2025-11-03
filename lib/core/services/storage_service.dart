import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  static SharedPreferences? _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Token methods
  Future<void> saveToken(String token) async {
    await _preferences?.setString('auth_token', token);
  }

 Future<String?> getToken() async {
    return _preferences?.getString('auth_token');
  }

  Future<void> clearToken() async {
    await _preferences?.remove('auth_token');
  }

 // User methods
 Future<void> saveUser(User user) async {
   await _preferences?.setString('user_data', user.toJsonString());
 }

 Future<User?> getUser() async {
   final userData = _preferences?.getString('user_data');
   if (userData != null) {
     return User.fromJsonString(userData);
   }
   return null;
 }

  Future<void> clearUser() async {
    await _preferences?.remove('user_data');
  }

  // Clear all auth data
 Future<void> clearAll() async {
    await _preferences?.remove('auth_token');
    await _preferences?.remove('user_data');
  }
}