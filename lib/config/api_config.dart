class ApiConfig {
  // Base URLs
  static const String prodBaseUrl = 'https://advance-company-backend-production.up.railway.app/api';
  static const String devBaseUrl = 'http://localhost:8000/api';
  
  // Use production URL by default (change for development)
  static const String baseUrl = prodBaseUrl;
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // API Version
  static const String apiVersion = 'v1';
}