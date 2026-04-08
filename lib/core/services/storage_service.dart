import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user_model.dart';

class StorageService {
  static SharedPreferences? _preferences;
  static Future<void>? _initFuture;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

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

    // Миграция: если токен ещё в SharedPreferences, перемещаем в SecureStorage
    final oldToken = _preferences?.getString(_tokenKey);
    if (oldToken != null) {
      await _secureStorage.write(key: _tokenKey, value: oldToken);
      await _preferences?.remove(_tokenKey);
    }
  }

  Future<void> init() async {
    await ensureInitialized();
  }

  // --- Токен (зашифрованное хранилище) ---

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // --- Данные пользователя (SharedPreferences — некритичные) ---

  Future<void> saveUser(User user) async {
    await ensureInitialized();
    await _preferences?.setString(_userDataKey, user.toJsonString());
  }

  Future<User?> getUser() async {
    await ensureInitialized();
    final userData = _preferences?.getString(_userDataKey);
    if (userData != null) {
      return User.fromJsonString(userData);
    }
    return null;
  }

  Future<void> clearUser() async {
    await ensureInitialized();
    await _preferences?.remove(_userDataKey);
  }

  Future<void> clearAll() async {
    await _secureStorage.delete(key: _tokenKey);
    await ensureInitialized();
    await _preferences?.remove(_userDataKey);
  }
}
