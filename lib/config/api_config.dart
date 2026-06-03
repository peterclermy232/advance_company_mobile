// lib/config/api_config.dart

class ApiConfig {
  static const String prodBaseUrl =
      'https://advance-company-backend-v1-0-3.onrender.com/api';
  static const String devBaseUrl =
      'https://advance-company-backend-v1-0-3.onrender.com/api';

  static const bool _isProduction = true;

  static String get baseUrl => _isProduction ? prodBaseUrl : devBaseUrl;

  // Render free tier cold-starts can take 50+ seconds.
  // Raise timeouts so the first login attempt doesn't time out.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout    = Duration(seconds: 90);
}