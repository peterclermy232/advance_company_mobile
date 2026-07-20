import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';

// ── Login result ────────────────────────────────────────────────────────────

enum LoginStatus { success, twoFactorRequired }

class LoginResult {
  final LoginStatus status;
  final UserModel? user;
  final String? tempToken;
  final String? email;

  const LoginResult({
    required this.status,
    this.user,
    this.tempToken,
    this.email,
  });
}

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

  // ── Envelope helper ─────────────────────────────────────────────────────────

  /// Backend wraps responses in {success, message, toast_type, data}.
  /// This unwraps to return the inner payload, falling back to the
  /// raw map when no envelope is present.
  Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    if (raw.containsKey('data') && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw;
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final raw = response.data as Map<String, dynamic>;
    final payload = _unwrap(raw);

    // 2FA challenge
    if (payload['requires_2fa'] == true) {
      return LoginResult(
        status: LoginStatus.twoFactorRequired,
        tempToken: payload['temp_token'] as String?,
        email: payload['email'] as String? ?? email,
      );
    }

    // Normal success — tokens may be nested under 'tokens' or flat
    final tokens = payload['tokens'] as Map<String, dynamic>?;
    final access = tokens?['access'] as String? ??
        payload['access'] as String? ?? '';
    final refresh = tokens?['refresh'] as String? ??
        payload['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);

    if (payload.containsKey('user') && payload['user'] is Map<String, dynamic>) {
      final user = UserModel.fromJson(payload['user'] as Map<String, dynamic>);
      return LoginResult(status: LoginStatus.success, user: user);
    }
    final user = await getProfile();
    return LoginResult(status: LoginStatus.success, user: user);
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
      ApiEndpoints.updateProfile(profile.uuid),
      data: data,
    );
    final raw = response.data as Map<String, dynamic>;
    final payload = _unwrap(raw);
    return UserModel.fromJson(payload);
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

  Future<void> resendVerification(String email) async {
    await _apiClient.post(
      ApiEndpoints.resendVerification,
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

  Future<UserModel> verify2FA({
    required String tempToken,
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verify2FA,
      data: {
        'temp_token': tempToken,
        'token_code': code,
      },
    );
    final raw = response.data as Map<String, dynamic>;
    final payload = _unwrap(raw);

    final tokens = payload['tokens'] as Map<String, dynamic>?;
    final access = tokens?['access'] as String? ??
        payload['access'] as String? ?? '';
    final refresh = tokens?['refresh'] as String? ??
        payload['refresh'] as String?;
    await _saveTokens(access: access, refresh: refresh);

    if (payload.containsKey('user') && payload['user'] is Map<String, dynamic>) {
      return UserModel.fromJson(payload['user'] as Map<String, dynamic>);
    }
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