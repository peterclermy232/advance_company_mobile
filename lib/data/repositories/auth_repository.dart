// lib/data/repositories/auth_repository.dart

import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/api_endpoints.dart';

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  const AuthRepository(this._api, this._storage);

  Future<UserModel> login({
    required String email,
    required String password,
    String? otpCode,
  }) async {
    final body = {
      'email': email,
      'password': password,
      if (otpCode != null) 'otp': otpCode,
    };
    final res = await _api.post(ApiEndpoints.login, data: body);
    final data = res.data as Map<String, dynamic>;

    final tokens = data['tokens'] as Map<String, dynamic>?;
    if (tokens != null) {
      await _storage.saveAccessToken(tokens['access'] as String);
      await _storage.saveRefreshToken(tokens['refresh'] as String);
    } else {
      await _storage.saveAccessToken(data['access'] as String? ?? '');
      await _storage.saveRefreshToken(data['refresh'] as String? ?? '');
    }

    final userData = (data['user'] ?? data) as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);
    await _storage.saveUserId(user.id.toString());
    await _storage.saveUserRole(user.role);
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final res = await _api.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final userData = (data['user'] ?? data) as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  Future<UserModel> getProfile() async {
    final res = await _api.get(ApiEndpoints.userProfile);
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh != null) {
        await _api.post(ApiEndpoints.logout, data: {'refresh': refresh});
      }
    } catch (_) { /* Best effort */ }
    await _storage.clearAll();
  }

  Future<void> verifyEmail(String token) async {
    await _api.post(ApiEndpoints.verifyEmail, data: {'token': token});
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post(ApiEndpoints.resetPassword, data: {
      'token': token,
      'password': newPassword,
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post(ApiEndpoints.changePassword, data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}