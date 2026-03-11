// lib/core/network/interceptors.dart

import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  // Public endpoints that don't need an auth token
  static const _publicEndpoints = [
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.verifyEmail,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
    ApiEndpoints.refreshToken,
  ];

  AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final isPublic = _publicEndpoints.any((e) => options.path.contains(e));

    if (!isPublic) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // Only handle 401, don't loop on refresh endpoint itself
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        _isRefreshing = true;
        try {
          final response = await _dio.post(
            ApiEndpoints.refreshToken,
            data: {'refresh': refreshToken},
          );

          final newAccessToken = response.data['access'] as String?;
          if (newAccessToken != null) {
            await _storage.saveAccessToken(newAccessToken);

            // Retry original request with new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed — clear session so router redirects to login
          await _storage.clearAll();
        } finally {
          _isRefreshing = false;
        }
      } else {
        // No refresh token — clear and let router redirect
        await _storage.clearAll();
      }
    }

    handler.next(err);
  }
}