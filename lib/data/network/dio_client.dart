// lib/data/network/dio_client.dart
//
// FIXED:
//   • tokenStorageProvider was referenced but undefined — now uses secureStorageProvider
//   • PrettyDioLogger disabled (was logging passwords in production)
//   • Token refresh on 401 handled in interceptor

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../providers/core_providers.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final dioClientProvider = Provider<Dio>((ref) {
  final dio = _buildDio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth token on public endpoints
        final publicEndpoints = [
          ApiEndpoints.login,
          ApiEndpoints.register,
          ApiEndpoints.verifyEmail,
          ApiEndpoints.forgotPassword,
          ApiEndpoints.resetPassword,
        ];

        final isPublic = publicEndpoints.any(
              (e) => options.path.contains(e),
        );

        if (!isPublic) {
          // FIX: use secureStorageProvider (not undefined tokenStorageProvider)
          final storage = await ref.read(secureStorageProvider.future);
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },

      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try refreshing the token
          try {
            final storage = await ref.read(secureStorageProvider.future);
            final refreshToken = await storage.getRefreshToken();
            if (refreshToken != null) {
              final refreshDio = _buildDio();
              final resp = await refreshDio.post(
                ApiEndpoints.refreshToken,
                data: {'refresh': refreshToken},
              );
              final newToken = resp.data['access'] as String;
              await storage.saveAccessToken(newToken);

              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResp = await dio.fetch(opts);
              return handler.resolve(retryResp);
            }
          } catch (_) {
            // Refresh failed — clear session
            final storage = await ref.read(secureStorageProvider.future);
            await storage.clearAll();
          }
        }

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: _friendlyError(error),
            type: error.type,
            response: error.response,
          ),
        );
      },
    ),
  );

  // FIX: PrettyDioLogger only in debug — was leaking passwords in production
  if (kDebugMode) {
    // Uncomment to enable request logging during development:
    // dio.interceptors.add(PrettyDioLogger(
    //   requestBody: false, // Keep false — avoids logging passwords
    //   responseBody: true,
    // ));
  }

  return dio;
});

// ── Build base Dio ─────────────────────────────────────────────────────────
Dio _buildDio() {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}

// ── Friendly error messages ────────────────────────────────────────────────
String _friendlyError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Cannot reach the server.\n\n'
          'Check:\n'
          '• Is the server running? (python manage.py runserver 0.0.0.0:8000)\n'
          '• Is the URL correct in api_config.dart?\n'
          '  Physical device → use your PC\'s LAN IP (e.g. 192.168.x.x)\n'
          '  Android Emulator → use 10.0.2.2\n'
          '  iOS Simulator → use 127.0.0.1\n'
          '• Are you on the same Wi-Fi as your PC?';

    case DioExceptionType.receiveTimeout:
      return 'Server is taking too long to respond. '
          'Check server logs for errors.';

    case DioExceptionType.sendTimeout:
      return 'Upload timed out. Check your connection speed.';

    case DioExceptionType.connectionError:
      return 'No connection to server. '
          'Verify the server URL in api_config.dart.';

    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 401) return 'Session expired. Please log in again.';
      if (status == 403) return 'Access denied.';
      if (status == 404) return 'Endpoint not found (404). Check API URLs.';
      if (status == 500) return 'Server error (500). Check Django logs.';
      if (data is Map) {
        final detail = data['detail'] ??
            data['message'] ??
            data['error'] ??
            data.values.firstOrNull;
        if (detail != null) return detail.toString();
      }
      return 'Server returned error $status.';

    case DioExceptionType.cancel:
      return 'Request was cancelled.';

    default:
      return e.message ?? 'An unexpected network error occurred.';
  }
}

// ── Retry helper ──────────────────────────────────────────────────────────────
Future<T> withRetry<T>(
    Future<T> Function() call, {
      int maxAttempts = 2,
    }) async {
  int attempt = 0;
  while (true) {
    try {
      attempt++;
      return await call();
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      if (isTimeout && attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt));
        continue;
      }
      rethrow;
    }
  }
}