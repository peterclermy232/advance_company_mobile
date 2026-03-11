
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// SharedPreferences — overridden at app startup in main.dart
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>(
      (ref) => throw UnimplementedError('Override in ProviderScope'),
);

// ---------------------------------------------------------------------------
// Dio — configured with base URL and interceptors
// ---------------------------------------------------------------------------
final dioProvider = Provider<Dio>((ref) {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.advancecompany.co.ke/api/v1',
  );

  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  // Attach stored token on each request
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final prefs = ref.read(sharedPreferencesProvider);
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto-refresh on 401
        if (error.response?.statusCode == 401) {
          try {
            final prefs = ref.read(sharedPreferencesProvider);
            final refresh = prefs.getString('refresh_token');
            if (refresh != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/token/refresh/',
                data: {'refresh': refresh},
              );
              final newAccess = response.data['access'] as String;
              await prefs.setString('access_token', newAccess);
              // Retry original request
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retried = await dio.fetch(opts);
              return handler.resolve(retried);
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});