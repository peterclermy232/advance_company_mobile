// ============================================
// lib/core/network/interceptors.dart
// ============================================
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for public endpoints
    final publicEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.verifyEmail,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
    ];

    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    if (!isPublicEndpoint) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 - Token expired
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          // Try to refresh token
          final response = await _dio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh': refreshToken},
          );

          final newAccessToken = response.data['access'];
          await _storage.saveAccessToken(newAccessToken);

          // Retry original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';
          
          final retryResponse = await _dio.fetch(options);
          return handler.resolve(retryResponse);
        } catch (e) {
          // Refresh failed - clear tokens and redirect to login
          await _storage.clearAll();
          return handler.reject(err);
        }
      }
    }

    handler.next(err);
  }
}