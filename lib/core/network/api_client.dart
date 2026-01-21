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

    _dio.interceptors.addAll([
      AuthInterceptor(_storage, _dio),
      if (kDebugMode) // Only log in debug mode
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }

  Dio get dio => _dio;

  // GET Request with retry logic
  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        int maxRetries = 3,
      }) async {
    return _executeWithRetry(
          () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      maxRetries: maxRetries,
    );
  }

  // POST Request with retry logic
  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        int maxRetries = 3,
      }) async {
    return _executeWithRetry(
          () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      maxRetries: maxRetries,
    );
  }

  // PUT Request
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

  // PATCH Request
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

  // DELETE Request
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

  // Upload File
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
        options: options,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Retry logic helper
  Future<Response> _executeWithRetry(
      Future<Response> Function() request, {
        int maxRetries = 3,
      }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        if (retryCount == maxRetries - 1 || !_shouldRetry(e)) {
          throw _handleError(e);
        }
        retryCount++;

        // Exponential backoff: wait 2s, 4s, 8s...
        await Future.delayed(Duration(seconds: 2 * retryCount));

        if (kDebugMode) {
          print('🔄 Retry attempt $retryCount of ${maxRetries - 1}');
        }
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Determine if error is retryable
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  Exception _handleError(DioException error) {
    if (kDebugMode) {
      print('❌ DioException Type: ${error.type}');
      print('❌ Error Message: ${error.message}');
      print('❌ Response: ${error.response?.data}');
      print('❌ Status Code: ${error.response?.statusCode}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');

      case DioExceptionType.connectionError:
        return kIsWeb
            ? Exception(
            'Cannot connect to server. Please ensure the backend is running '
                'and CORS is configured properly.')
            : Exception(
            'Network error. Please check your internet connection and try again.');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return Exception('Request cancelled.');

      case DioExceptionType.badCertificate:
        return Exception('Security certificate error.');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return Exception('No internet connection.');
        }
        return Exception(error.message ?? 'An unexpected error occurred.');

      default:
        return Exception('An error occurred. Please try again.');
    }
  }

  Exception _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 401:
        return Exception('Session expired. Please login again.');
      case 403:
        return Exception('Access denied.');
      case 404:
        return Exception('Resource not found.');
      case 422:
        return Exception('Validation error. Please check your input.');
      case 500:
      case 502:
      case 503:
        return Exception('Server error. Please try again later.');
      default:
        return _parseErrorMessage(data);
    }
  }

  Exception _parseErrorMessage(dynamic data) {
    if (data is Map) {
      // Try common error field names
      final message = data['message'] ??
          data['error'] ??
          data['detail'] ??
          data['non_field_errors'];

      if (message != null) {
        return Exception(message is List ? message.join(', ') : message.toString());
      }

      // Handle field-specific errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.join(', ')}');
        } else if (value is String) {
          errors.add('$key: $value');
        }
      });

      if (errors.isNotEmpty) {
        return Exception(errors.join('\n'));
      }
    }

    return Exception('An error occurred. Please try again.');
  }
}