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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Important for better error handling
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_storage, _dio),
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

  // GET Request
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

  // POST Request
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

  Exception _handleError(DioException error) {
    // Log error details in debug mode
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
        return Exception('Connection timeout. Please check your internet connection and try again.');

      case DioExceptionType.connectionError:
        // This is the error you're experiencing
        if (kIsWeb) {
          return Exception(
            'Network Error: Unable to connect to server.\n\n'
            'Possible causes:\n'
            '1. Backend server is not running\n'
            '2. CORS is not configured on backend\n'
            '3. Wrong API URL: ${ApiConfig.baseUrl}\n\n'
            'Solutions:\n'
            '• Start Django server: python manage.py runserver\n'
            '• Install django-cors-headers\n'
            '• Add CORS_ALLOW_ALL_ORIGINS = True to settings.py'
          );
        } else {
          return Exception(
            'Network Error: Cannot connect to server.\n\n'
            'Please check:\n'
            '• Your internet connection\n'
            '• Backend server is running\n'
            '• API URL is correct: ${ApiConfig.baseUrl}'
          );
        }

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return Exception('Unauthorized. Please login again.');
        } else if (statusCode == 403) {
          return Exception('Access forbidden.');
        } else if (statusCode == 404) {
          return Exception('Resource not found.');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }

        // Handle backend error response format
        if (data is Map) {
          // Try different common error field names
          final message = data['message'] ?? 
                         data['error'] ?? 
                         data['detail'] ?? 
                         data['non_field_errors'];
          
          if (message != null) {
            if (message is List) {
              return Exception(message.join(', '));
            }
            return Exception(message.toString());
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

      case DioExceptionType.cancel:
        return Exception('Request cancelled.');

      case DioExceptionType.badCertificate:
        return Exception('Security certificate error. Please check your connection.');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return Exception('No internet connection. Please check your network settings.');
        }
        if (error.message?.contains('HandshakeException') ?? false) {
          return Exception('Connection security error. Please try again.');
        }
        return Exception('An unexpected error occurred: ${error.message ?? 'Unknown error'}');

      default:
        return Exception('An error occurred. Please try again.');
    }
  }
}