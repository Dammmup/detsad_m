import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  static SharedPreferences? _preferences;
  
  // Ensure that the preferences are initialized before use
  static Future<void> ensureInitialized() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    await ensureInitialized();
  }

  // Token methods
  Future<void> saveToken(String token) async {
    await ensureInitialized();
    await _preferences?.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    await ensureInitialized();
    return _preferences?.getString('auth_token');
  }

  Future<void> clearToken() async {
    await ensureInitialized();
    await _preferences?.remove('auth_token');
  }

 // User methods
 Future<void> saveUser(User user) async {
   await ensureInitialized();
   await _preferences?.setString('user_data', user.toJsonString());
 }

 Future<User?> getUser() async {
   await ensureInitialized();
   final userData = _preferences?.getString('user_data');
   if (userData != null) {
     return User.fromJsonString(userData);
   }
   return null;
 }

  Future<void> clearUser() async {
    await ensureInitialized();
    await _preferences?.remove('user_data');
  }

  // Clear all auth data
 Future<void> clearAll() async {
    await ensureInitialized();
    await _preferences?.remove('auth_token');
    await _preferences?.remove('user_data');
  }
}