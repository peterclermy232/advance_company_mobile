// lib/data/network/dio_client.dart
//
// Replace your existing Dio setup with this file.
// It adds: retry on timeout, clearer error messages, request logging.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../providers/auth_provider.dart'; // adjust import if needed

// ── Provider ──────────────────────────────────────────────────────────────────
final dioClientProvider = Provider<Dio>((ref) {
  final dio = _buildDio();

  // Attach auth token from storage on every request
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref
            .read(tokenStorageProvider)
            .getAccessToken(); // adjust to your token storage
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Convert Dio errors into human-readable exceptions
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

  // Optional: pretty-print logs in debug mode
  // dio.interceptors.add(PrettyDioLogger());

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
          'Verify the server URL in api_config.dart and that '
          'android:usesCleartextTraffic="true" is set for HTTP.';

    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 401) return 'Session expired. Please log in again.';
      if (status == 403) return 'Access denied.';
      if (status == 404) return 'Endpoint not found (404). Check API URLs.';
      if (status == 500) return 'Server error (500). Check Django logs.';
      // Try to extract Django REST Framework error detail
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
// Wrap API calls with this to get 1 automatic retry on timeout.
//
// Usage:
//   final response = await withRetry(() => dio.get('/endpoint'));
//
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
        // Wait briefly then retry
        await Future.delayed(Duration(seconds: attempt));
        continue;
      }
      rethrow;
    }
  }
}