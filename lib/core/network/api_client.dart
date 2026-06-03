import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../storage/secure_storage.dart';
import '../../config/api_config.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // ── Auth interceptor: inject token + auto-refresh on 401 ────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final refresh = await _storage.getRefreshToken();
              if (refresh != null) {
                final refreshDio = Dio(
                  BaseOptions(baseUrl: ApiConfig.baseUrl),
                );
                final response = await refreshDio.post(
                  '/token/refresh/',
                  data: {'refresh': refresh},
                );
                final newAccess = response.data['access'] as String;
                await _storage.saveAccessToken(newAccess);
                // Retry original request with new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                final retried = await _dio.fetch(opts);
                return handler.resolve(retried);
              }
            } catch (_) {
              await _storage.clearAll(); // force logout on refresh failure
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false, // avoid logging auth token
          requestBody: false, // avoid logging passwords
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadFile(
    String path,
    FormData formData, {
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: options ?? Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  Exception _handleError(DioException error) {
    if (kDebugMode) {
      debugPrint('❌ DioException [${error.type}]: ${error.message}');
      debugPrint('   Response: ${error.response?.data}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
          'Cannot reach the server.\n\n'
          'Check:\n'
          '• Is the server running?\n'
          '• Is the API URL correct in api_config.dart?\n'
          '  Physical device → use your PC\'s LAN IP (e.g. 192.168.x.x)\n'
          '  Android Emulator → use 10.0.2.2\n'
          '  iOS Simulator → use 127.0.0.1\n'
          '• Are you on the same Wi-Fi?',
        );
      case DioExceptionType.sendTimeout:
        return Exception('Upload timed out. Check your connection speed.');
      case DioExceptionType.receiveTimeout:
        return Exception('Server is taking too long to respond.');
      case DioExceptionType.connectionError:
        return Exception(
          'No connection to server. Verify the server URL '
          'and that android:usesCleartextTraffic="true" is set for HTTP.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return Exception('Session expired. Please log in again.');
        }
        if (statusCode == 403) {
          return Exception('Access denied.');
        }
        if (statusCode == 404) {
          return Exception('Endpoint not found (404). Check API URLs.');
        }
        if (statusCode == 500) {
          return Exception('Server error (500). Check server logs.');
        }

        if (data is Map) {
          final message = data['message'] ??
              data['error'] ??
              data['detail'] ??
              data['non_field_errors'];
          if (message != null) {
            return Exception(
              message is List ? message.join(', ') : message.toString(),
            );
          }
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.add(value.join(', '));
            } else if (value is String) {
              errors.add(value);
            }
          });
          if (errors.isNotEmpty) {
            return Exception(errors.join('\n'));
          }
        }
        return Exception('An error occurred (HTTP $statusCode).');

      case DioExceptionType.cancel:
        return Exception('Request cancelled.');
      case DioExceptionType.badCertificate:
        return Exception('Security certificate error.');
      case DioExceptionType.unknown:
        final msg = error.message ?? '';
        if (msg.contains('SocketException')) {
          return Exception('No internet connection.');
        }
        return Exception('An unexpected error occurred.');
    }
  }
}
