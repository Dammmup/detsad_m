import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  static SharedPreferences? _preferences;
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() async {
    if (_preferences != null) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = SharedPreferences.getInstance().then((prefs) {
      _preferences = prefs;
    });
    await _initFuture;
  }

  Future<void> init() async {
    await ensureInitialized();
  }

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

  Future<void> clearAll() async {
    await ensureInitialized();
    await _preferences?.remove('auth_token');
    await _preferences?.remove('user_data');
  }
}
