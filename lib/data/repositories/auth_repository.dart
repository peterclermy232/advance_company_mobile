import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<String?> getStoredToken() => _storage.getAccessToken();

  Future<void> _saveTokens({
    required String access,
    String? refresh,
  }) async {
    await _storage.saveAccessToken(access);
    if (refresh != null) await _storage.saveRefreshToken(refresh);
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    final access = data['access'] as String? ?? data['token'] as String? ?? '';
    final refresh = data['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);

    if (data.containsKey('user')) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    return getProfile();
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await _apiClient.post(
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

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh != null) {
        await _apiClient.post(
          ApiEndpoints.logout,
          data: {'refresh': refresh},
        );
      }
    } catch (_) {}
    await _storage.clearAll();
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final profile = await getProfile();
    final response = await _apiClient.patch(
      ApiEndpoints.updateProfile(profile.id.toString()),
      data: data,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Password ───────────────────────────────────────────────────────────────

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': oldPassword,
        'new_password': newPassword,
        're_new_password': newPassword,
      },
    );
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'token': token,
        'password': newPassword,
        're_password': newPassword,
      },
    );
  }

  // ── Email verification ─────────────────────────────────────────────────────

  Future<void> verifyEmail({
    String? email,
    String? code,
    String? token,
  }) async {
    final Map<String, dynamic> body = {};
    if (token != null) {
      body['token'] = token;
    } else {
      if (email != null) body['email'] = email;
      if (code != null) body['code'] = code;
    }
    await _apiClient.post(ApiEndpoints.verifyEmail, data: body);
  }

  // ── 2FA ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> enable2FA() async {
    final response = await _apiClient.post(ApiEndpoints.enable2FA);
    return response.data as Map<String, dynamic>;
  }

  Future<void> confirm2FA(String code) async {
    await _apiClient.post(ApiEndpoints.confirm2FA, data: {'code': code});
  }

  Future<void> disable2FA(String password) async {
    await _apiClient.post(ApiEndpoints.disable2FA, data: {'password': password});
  }

  Future<UserModel> verify2FA(String code) async {
    final response = await _apiClient.post(
      ApiEndpoints.verify2FA,
      data: {'code': code},
    );
    final data = response.data as Map<String, dynamic>;
    final access = data['access'] as String? ?? '';
    final refresh = data['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);
    return getProfile();
  }

  // ── Token refresh ──────────────────────────────────────────────────────────

  Future<bool> refreshToken() async {
    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null) return false;
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refresh},
      );
      final access = response.data['access'] as String;
      await _storage.saveAccessToken(access);
      return true;
    } catch (_) {
      return false;
    }
  }
}