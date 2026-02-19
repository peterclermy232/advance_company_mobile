import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';
import 'dart:convert';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      print('🔐 RAW LOGIN RESPONSE: ${response.data}');

      final responseBody = response.data;

      if (responseBody['success'] != true) {
        throw Exception(responseBody['message'] ?? 'Login failed');
      }

      final data = responseBody['data'];
      final authResponse = AuthResponse.fromJson(data);

      await _storage.saveAccessToken(authResponse.accessToken);
      await _storage.saveRefreshToken(authResponse.refreshToken);
      await _storage.saveUserData(jsonEncode(authResponse.user.toJson()));

      print('✅ AUTH REPO LOGIN: user=${authResponse.user.email}');
      return authResponse;
    } catch (e) {
      print('❌ AUTH REPO LOGIN ERROR: $e');
      rethrow;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<AuthResponse> register(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: data,
      );

      final responseBody = response.data;
      if (responseBody['success'] != true) {
        throw Exception(responseBody['message'] ?? 'Registration failed');
      }

      final authResponse = AuthResponse.fromJson(responseBody['data']);

      await _storage.saveAccessToken(authResponse.accessToken);
      await _storage.saveRefreshToken(authResponse.refreshToken);
      await _storage.saveUserData(jsonEncode(authResponse.user.toJson()));

      return authResponse;
    } catch (e) {
      print('❌ AUTH REPO REGISTER ERROR: $e');
      rethrow;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _storage.clearAll();
    } catch (e) {
      print('❌ LOGOUT ERROR: $e');
      await _storage.clearAll();
    }
  }

  // ─── Get Current User (from local storage) ────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = await _storage.getUserData();
      if (userData == null || userData.isEmpty) return null;

      final decoded = jsonDecode(userData);
      final user = UserModel.fromJson(decoded);
      print('✅ CURRENT USER FROM STORAGE: ${user.email}');
      return user;
    } catch (e) {
      print('❌ GET CURRENT USER ERROR: $e');
      return null; // ✅ Return null instead of crashing
    }
  }

  // ─── Get User Profile (from API) ──────────────────────────────────────────
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.currentUser);
      final data = response.data;

      final userData = data['data'] ?? data;
      final user = UserModel.fromJson(userData);

      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      print('❌ GET USER PROFILE ERROR: $e');
      rethrow;
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────────────
  Future<UserModel> updateProfile(int userId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateProfile.replaceAll('{id}', userId.toString()),
        data: data,
      );

      final user = UserModel.fromJson(response.data['data']);
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      print('❌ UPDATE PROFILE ERROR: $e');
      rethrow;
    }
  }

  // ─── Change Password ──────────────────────────────────────────────────────
  Future<void> changePassword(Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.changePassword, data: data);
  }

  // ─── 2FA ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> enable2FA() async {
    final response = await _apiClient.post(ApiEndpoints.enable2FA, data: {});
    return response.data['data'];
  }

  Future<Map<String, dynamic>> confirm2FA(String code) async {
    final response = await _apiClient.post(
      ApiEndpoints.confirm2FA,
      data: {'code': code},
    );
    return response.data['data'];
  }

  Future<void> disable2FA(String password) async {
    await _apiClient.post(
      ApiEndpoints.disable2FA,
      data: {'password': password},
    );
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  // ─── Verify Email ─────────────────────────────────────────────────────────
  Future<void> verifyEmail(String email, String token) async {
    await _apiClient.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'token': token},
    );
  }

  // ─── Upload Profile Photo ─────────────────────────────────────────────────
  Future<UserModel> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.uploadFile(
      '/auth/users/upload_profile_photo/',
      formData,
    );

    final user = UserModel.fromJson(response.data['data']['user']);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }
}