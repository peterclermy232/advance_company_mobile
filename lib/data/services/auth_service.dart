// lib/data/services/auth_service.dart
// Authentication service aligned with backend JWT authentication model

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Login endpoint
  /// Returns: { "tokens": { "access": "...", "refresh": "..." }, "user": {...} }
  /// If 2FA enabled: { "requires_2fa": true, "temp_token": "...", "email": "..." }
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Register endpoint
  /// Body: { "email", "phone_number", "full_name", "password", "password_confirm", "role" }
  Future<void> register({
    required String email,
    required String phoneNumber,
    required String fullName,
    required String password,
    required String passwordConfirm,
    String role = 'user',
  }) async {
    await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'password': password,
        'password_confirm': passwordConfirm,
        'role': role,
      },
    );
  }

  /// Verify email endpoint
  Future<void> verifyEmail({
    String? token,
    String? code,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (token != null) data['token'] = token;
    if (code != null) data['code'] = code;
    if (email != null) data['email'] = email;

    await _apiClient.post(ApiEndpoints.verifyEmail, data: data);
  }

  /// Resend verification email
  Future<void> resendVerification({required String email}) async {
    await _apiClient.post(
      ApiEndpoints.resendVerification,
      data: {'email': email},
    );
  }

  /// Verify 2FA code
  /// Body: { "temp_token", "token_code" or "backup_code" }
  Future<AuthResponse> verify2FA({
    required String tempToken,
    String? tokenCode,
    String? backupCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verify2FA,
      data: {
        'temp_token': tempToken,
        if (tokenCode != null) 'token_code': tokenCode,
        if (backupCode != null) 'backup_code': backupCode,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Forgot password endpoint
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// Reset password with token
  Future<void> resetPasswordConfirm({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _apiClient.post(
      ApiEndpoints.resetPasswordConfirm,
      data: {
        'token': token,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }

  /// Refresh access token
  /// Body: { "refresh": "<refresh_token>" }
  /// Returns: { "access": "new_token" }
  Future<String> refreshToken({required String refreshToken}) async {
    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {'refresh': refreshToken},
    );
    return response.data['access'] as String;
  }

  /// Get current user profile (requires auth)
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.users);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get user by UUID (requires auth)
  Future<UserModel> getUserByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.userDetail(uuid));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update user profile (requires auth)
  /// Supports partial updates
  Future<UserModel> updateUser(
    String uuid, {
    String? fullName,
    String? phoneNumber,
    int? age,
    String? gender,
    String? maritalStatus,
    int? numberOfKids,
    String? profession,
    String? salaryRange,
    String? spouseName,
    int? spouseAge,
    String? spouseProfession,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (maritalStatus != null) data['marital_status'] = maritalStatus;
    if (numberOfKids != null) data['number_of_kids'] = numberOfKids;
    if (profession != null) data['profession'] = profession;
    if (salaryRange != null) data['salary_range'] = salaryRange;
    if (spouseName != null) data['spouse_name'] = spouseName;
    if (spouseAge != null) data['spouse_age'] = spouseAge;
    if (spouseProfession != null) data['spouse_profession'] = spouseProfession;

    final response = await _apiClient.patch(
      ApiEndpoints.updateUser(uuid),
      data: data,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete user account (requires auth)
  Future<void> deleteUser(String uuid) async {
    await _apiClient.delete(ApiEndpoints.deleteUser(uuid));
  }

  /// Change password (requires auth)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
  }

  /// Enable 2FA (requires auth)
  /// Returns setup instructions and backup codes
  Future<Map<String, dynamic>> enable2FA() async {
    final response = await _apiClient.post(ApiEndpoints.enable2FA);
    return response.data as Map<String, dynamic>;
  }

  /// Confirm 2FA setup (requires auth)
  /// Body: { "token_code": "123456" }
  Future<List<String>> confirm2FA({required String tokenCode}) async {
    final response = await _apiClient.post(
      ApiEndpoints.confirm2FA,
      data: {'token_code': tokenCode},
    );
    // Returns backup codes
    return List<String>.from(response.data['backup_codes'] as List);
  }

  /// Disable 2FA (requires auth)
  Future<void> disable2FA() async {
    await _apiClient.post(ApiEndpoints.disable2FA);
  }

  /// Regenerate 2FA backup codes (requires auth)
  Future<List<String>> regenerateBackupCodes() async {
    final response = await _apiClient.post(ApiEndpoints.regenerateBackupCodes);
    return List<String>.from(response.data['backup_codes'] as List);
  }

  /// Register biometric (requires auth)
  /// Body: { "device_name", "biometric_type" }
  Future<Map<String, dynamic>> registerBiometric({
    required String deviceName,
    required String biometricType,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerBiometric,
      data: {
        'device_name': deviceName,
        'biometric_type': biometricType,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get biometric devices (requires auth)
  Future<List<Map<String, dynamic>>> getBiometricDevices() async {
    final response = await _apiClient.get(ApiEndpoints.biometricDevices);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  /// Delete biometric device (requires auth)
  Future<void> deleteBiometricDevice(String uuid, String deviceId) async {
    await _apiClient.delete(ApiEndpoints.deleteBiometricDevice(uuid, deviceId));
  }

  /// Upload profile photo (requires auth)
  /// Body: FormData with "profile_photo" file field
  Future<UserModel> uploadProfilePhoto(
      List<int> fileBytes, String fileName) async {
    final formData = FormData.fromMap({
      'profile_photo': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await _apiClient.post(
      ApiEndpoints.uploadProfilePhoto,
      data: formData,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete profile photo (requires auth)
  Future<void> deleteProfilePhoto() async {
    await _apiClient.delete(ApiEndpoints.deleteProfilePhoto);
  }

  /// Delete account (requires auth)
  Future<void> deleteAccount() async {
    await _apiClient.post(ApiEndpoints.deleteAccount);
  }
}
