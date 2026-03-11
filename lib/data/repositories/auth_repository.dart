
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';

class AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  AuthRepository({required Dio dio, required SharedPreferences prefs})
      : _dio = dio,
        _prefs = prefs;

  String? getStoredToken() => _prefs.getString(_tokenKey);

  Future<void> _saveTokens({
    required String access,
    String? refresh,
  }) async {
    await _prefs.setString(_tokenKey, access);
    if (refresh != null) {
      await _prefs.setString(_refreshTokenKey, refresh);
    }
    _dio.options.headers['Authorization'] = 'Bearer $access';
  }

  Future<void> _clearTokens() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    _dio.options.headers.remove('Authorization');
  }

  // -------------------------------------------------------------------------
  // Login
  // -------------------------------------------------------------------------
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    final access = data['access'] as String? ?? data['token'] as String? ?? '';
    final refresh = data['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);

    // If the login response already contains user info use it, else fetch
    if (data.containsKey('user')) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    return getProfile();
  }

  // -------------------------------------------------------------------------
  // Register
  // -------------------------------------------------------------------------
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        're_password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
  }

  // -------------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    try {
      final refresh = _prefs.getString(_refreshTokenKey);
      if (refresh != null) {
        await _dio.post(ApiEndpoints.logout, data: {'refresh': refresh});
      }
    } catch (_) {}
    await _clearTokens();
  }

  // -------------------------------------------------------------------------
  // Get Profile  — uses ApiEndpoints.currentUser (was wrongly referencing
  //                a non-existent 'userProfile' key in old code)
  // -------------------------------------------------------------------------
  Future<UserModel> getProfile() async {
    final token = getStoredToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _dio.get(ApiEndpoints.currentUser);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Update Profile
  // -------------------------------------------------------------------------
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final token = getStoredToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    // Fetch current user id first
    final profile = await getProfile();
    final response = await _dio.patch(
      ApiEndpoints.updateProfile(profile.id.toString()),
      data: data,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Change Password
  // -------------------------------------------------------------------------
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': oldPassword,
        'new_password': newPassword,
        're_new_password': newPassword,
      },
    );
  }

  // -------------------------------------------------------------------------
  // Verify Email — accepts both (email + code) and (token) call patterns
  //   Old screen passed email + code, repository previously only accepted token.
  //   Now we support both.
  // -------------------------------------------------------------------------
  Future<void> verifyEmail({String? email, String? code, String? token}) async {
    final Map<String, dynamic> body = {};
    if (token != null) {
      body['token'] = token;
    } else {
      if (email != null) body['email'] = email;
      if (code != null) body['code'] = code;
    }
    await _dio.post(ApiEndpoints.verifyEmail, data: body);
  }

  // -------------------------------------------------------------------------
  // Forgot / Reset Password
  // -------------------------------------------------------------------------
  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'token': token,
        'password': newPassword,
        're_password': newPassword,
      },
    );
  }

  // -------------------------------------------------------------------------
  // 2FA
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> enable2FA() async {
    final response = await _dio.post(ApiEndpoints.enable2FA);
    return response.data as Map<String, dynamic>;
  }

  Future<void> confirm2FA(String code) async {
    await _dio.post(ApiEndpoints.confirm2FA, data: {'code': code});
  }

  Future<void> disable2FA(String password) async {
    await _dio.post(ApiEndpoints.disable2FA, data: {'password': password});
  }

  Future<UserModel> verify2FA(String code) async {
    final response = await _dio.post(ApiEndpoints.verify2FA, data: {'code': code});
    final data = response.data as Map<String, dynamic>;
    final access = data['access'] as String? ?? '';
    final refresh = data['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);
    return getProfile();
  }

  // -------------------------------------------------------------------------
  // Refresh token
  // -------------------------------------------------------------------------
  Future<bool> refreshToken() async {
    try {
      final refresh = _prefs.getString(_refreshTokenKey);
      if (refresh == null) return false;
      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refresh},
      );
      final access = response.data['access'] as String;
      await _saveTokens(access: access);
      return true;
    } catch (_) {
      return false;
    }
  }
}