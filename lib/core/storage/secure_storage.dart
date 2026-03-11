// lib/core/storage/secure_storage.dart
//
// Centralised storage for auth tokens and user preferences.
// Wraps flutter_secure_storage (encrypted) + shared_preferences (non-sensitive).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  // Keys
  static const _kAccessToken  = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId       = 'user_id';
  static const _kUserRole     = 'user_role';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kOnboardingDone   = 'onboarding_done';

  const SecureStorage(this._secure, this._prefs);

  // ── Access token ────────────────────────────────────────────────────────────

  Future<String?> getAccessToken()   => _secure.read(key: _kAccessToken);
  Future<void> saveAccessToken(String t) => _secure.write(key: _kAccessToken, value: t);

  // ── Refresh token ───────────────────────────────────────────────────────────

  Future<String?> getRefreshToken()   => _secure.read(key: _kRefreshToken);
  Future<void> saveRefreshToken(String t) => _secure.write(key: _kRefreshToken, value: t);

  // ── User metadata ───────────────────────────────────────────────────────────

  Future<String?> getUserId()            => _secure.read(key: _kUserId);
  Future<void>    saveUserId(String id)  => _secure.write(key: _kUserId, value: id);

  String? getUserRole()            => _prefs.getString(_kUserRole);
  Future<void> saveUserRole(String role) async => _prefs.setString(_kUserRole, role);

  // ── Biometrics ──────────────────────────────────────────────────────────────

  bool isBiometricEnabled() => _prefs.getBool(_kBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool v) async => _prefs.setBool(_kBiometricEnabled, v);

  // ── Onboarding ──────────────────────────────────────────────────────────────

  bool isOnboardingDone() => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone() async => _prefs.setBool(_kOnboardingDone, true);

  // ── Session helpers ─────────────────────────────────────────────────────────

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Call on logout or token refresh failure.
  Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.remove(_kUserRole);
    await _prefs.remove(_kBiometricEnabled);
    // Keep onboarding flag so user doesn't see it again
  }
}