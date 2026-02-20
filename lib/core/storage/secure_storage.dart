// lib/core/storage/secure_storage.dart
//
// Plain class only — NO providers inside here.
// Providers live in core_providers.dart (see that file).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const String _accessTokenKey    = 'access_token';
  static const String _refreshTokenKey   = 'refresh_token';
  static const String _userDataKey       = 'user_data';
  static const String _biometricEnabledKey = 'biometric_enabled';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences    _prefs;

  SecureStorage(this._secureStorage, this._prefs);

  // Access Token
  Future<void>    saveAccessToken(String token) async =>
      _secureStorage.write(key: _accessTokenKey, value: token);
  Future<String?> getAccessToken() async =>
      _secureStorage.read(key: _accessTokenKey);

  // Refresh Token
  Future<void>    saveRefreshToken(String token) async =>
      _secureStorage.write(key: _refreshTokenKey, value: token);
  Future<String?> getRefreshToken() async =>
      _secureStorage.read(key: _refreshTokenKey);

  // User Data
  Future<void>    saveUserData(String userData) async =>
      _secureStorage.write(key: _userDataKey, value: userData);
  Future<String?> getUserData() async =>
      _secureStorage.read(key: _userDataKey);

  // Biometric Preference
  Future<void> setBiometricEnabled(bool enabled) async =>
      _prefs.setBool(_biometricEnabledKey, enabled);
  Future<bool> isBiometricEnabled() async =>
      _prefs.getBool(_biometricEnabledKey) ?? false;

  // Clear all
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}