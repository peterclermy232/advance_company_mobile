class ApiConfig {
  // Base URLs
  static const String prodBaseUrl = 'http://127.0.0.1:8000/api';
  static const String devBaseUrl = 'http://127.0.0.1:8000/api';

  // Environment-based URL selection
  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' ? prodBaseUrl : devBaseUrl;
  }

  // Timeouts - ADD THESE LINES
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // API Version
  static const String apiVersion = 'v1';

  // For local development on physical devices (optional)
  static const String localNetworkUrl = 'http://127.0.0.1:8000/api';
}