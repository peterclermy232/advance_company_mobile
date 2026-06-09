// lib/config/api_config.dart
import 'package:flutter/foundation.dart';

/// API configuration aligned with backend Django REST Framework setup
class ApiConfig {
  // ─────────────────────────────────────────────────────────────────────────────
  // Base URLs
  // ─────────────────────────────────────────────────────────────────────────────

  /// Production backend URL
  static const String prodBaseUrl =
      'https://advance-company-backend-v1-0-3.onrender.com/api';

  /// Development backend URL
  static String get devBaseUrl {
    if (kIsWeb) {
      // For Web, localhost refers to the same machine
      return 'http://localhost:8000/api';
    }
    // For Android Emulator, 10.0.2.2 maps to host localhost
    return 'http://10.0.2.2:8000/api';
  }

  /// Toggle between production and development
  /// Set to false for local development
  static const bool _isProduction = false;

  static String get baseUrl => _isProduction ? prodBaseUrl : devBaseUrl;

  // ─────────────────────────────────────────────────────────────────────────────
  // HTTP Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 90);

  // ─────────────────────────────────────────────────────────────────────────────
  // JWT Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  static const Duration accessTokenExpiry = Duration(minutes: 30);
  static const Duration refreshTokenExpiry = Duration(days: 7);

  // ─────────────────────────────────────────────────────────────────────────────
  // API Response Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  static const int defaultPageSize = 20;
  static const int maxFileUploadBytes = 10 * 1024 * 1024;

  static const String bearerTokenFormat = 'Bearer {token}';
  static const String userIdClaim = 'user_id';
}
