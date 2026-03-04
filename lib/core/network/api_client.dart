// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../storage/secure_storage.dart';
import '../../config/api_config.dart';
import 'interceptors.dart';

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

    _dio.interceptors.add(AuthInterceptor(_storage, _dio));

    // ⚠️  PrettyDioLogger MUST only run in debug mode.
    // It logs full request bodies — including passwords — which is a
    // security violation in production builds.
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false, // don't log Auth header (contains token)
          requestBody: false,   // don't log passwords
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // ── HTTP helpers ─────────────────────────────────────────────────────────

  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> patch(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> delete(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) { throw _handleError(e); }
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
    } on DioException catch (e) { throw _handleError(e); }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  Exception _handleError(DioException error) {
    if (kDebugMode) {
      debugPrint('❌ DioException [${error.type}]: ${error.message}');
      debugPrint('   Response: ${error.response?.data}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');

      case DioExceptionType.connectionError:
        return Exception(
          'Cannot connect to server.\n'
              'Check: server is running, API URL is correct, and you have internet.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) return Exception('Session expired. Please login again.');
        if (statusCode == 403) return Exception('Access denied.');
        if (statusCode == 404) return Exception('Resource not found.');
        if (statusCode == 500) return Exception('Server error. Please try again later.');

        if (data is Map) {
          final message = data['message'] ?? data['error'] ?? data['detail'] ?? data['non_field_errors'];
          if (message != null) {
            return Exception(message is List ? message.join(', ') : message.toString());
          }
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List)       errors.add(value.join(', '));
            else if (value is String) errors.add(value);
          });
          if (errors.isNotEmpty) return Exception(errors.join('\n'));
        }
        return Exception('An error occurred. Please try again.');

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

      default:
        return Exception('An error occurred. Please try again.');
    }
  }
}