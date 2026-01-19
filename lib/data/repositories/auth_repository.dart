// ============================================
// lib/data/repositories/auth_repository.dart
// ============================================
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

  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final data = response.data['data'];
    final authResponse = AuthResponse.fromJson(data);
    
    // Save tokens
    await _storage.saveAccessToken(authResponse.accessToken);
    await _storage.saveRefreshToken(authResponse.refreshToken);
    await _storage.saveUserData(jsonEncode(authResponse.user.toJson()));
    
    return authResponse;
  }

  Future<AuthResponse> register(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: data,
    );

    final responseData = response.data['data'];
    final authResponse = AuthResponse.fromJson(responseData);
    
    await _storage.saveAccessToken(authResponse.accessToken);
    await _storage.saveRefreshToken(authResponse.refreshToken);
    await _storage.saveUserData(jsonEncode(authResponse.user.toJson()));
    
    return authResponse;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData == null) return null;
    
    return UserModel.fromJson(jsonDecode(userData));
  }

  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get(ApiEndpoints.currentUser);
    final user = UserModel.fromJson(response.data['data']);
    
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> updateProfile(int userId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      ApiEndpoints.updateProfile.replaceAll('{id}', userId.toString()),
      data: data,
    );

    final user = UserModel.fromJson(response.data['data']);
    await _storage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> changePassword(Map<String, dynamic> data) async {
    await _apiClient.post(ApiEndpoints.changePassword, data: data);
  }

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

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> verifyEmail(String email, String token) async {
    await _apiClient.post(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'token': token},
    );
  }

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