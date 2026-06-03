// lib/config/api_config.dart
// API configuration aligned with backend Django REST Framework setup

class ApiConfig {
  // ─────────────────────────────────────────────────────────────────────────────
  // Base URLs (change devBaseUrl for local development)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Production backend URL
  static const String prodBaseUrl =
      'https://advance-company-backend-v1-0-3.onrender.com/api';

  /// Development backend URL
  /// For local development:
  /// - Android Emulator: http://10.0.2.2:8000/api
  /// - iOS Simulator: http://127.0.0.1:8000/api
  /// - Physical device: http://<your-pc-ip>:8000/api (e.g., 192.168.x.x)
  /// - Docker: http://localhost:8000/api or service name
  static const String devBaseUrl =
      'https://advance-company-backend-v1-0-3.onrender.com/api';

  /// Toggle between production and development
  /// Set to false for local development
  static const bool _isProduction = true;

  static String get baseUrl => _isProduction ? prodBaseUrl : devBaseUrl;

  // ─────────────────────────────────────────────────────────────────────────────
  // HTTP Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  /// Connect timeout - Render free tier cold-starts can take 50+ seconds
  static const Duration connectTimeout = Duration(seconds: 60);

  /// Receive timeout
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Send timeout - longer for file uploads
  static const Duration sendTimeout = Duration(seconds: 90);

  // ─────────────────────────────────────────────────────────────────────────────
  // JWT Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  /// Access token lifetime: 30 minutes
  static const Duration accessTokenExpiry = Duration(minutes: 30);

  /// Refresh token lifetime: 7 days
  static const Duration refreshTokenExpiry = Duration(days: 7);

  // ─────────────────────────────────────────────────────────────────────────────
  // API Response Configuration
  // ─────────────────────────────────────────────────────────────────────────────

  /// Standard response wrapper fields
  /// Some endpoints return: { "success": bool, "message": string, "toast_type": string, "data": {...} }
  /// Other endpoints return raw DRF data or paginated: { "count": N, "next": "...", "results": [...] }
  /// Frontend services must handle both patterns

  /// Default page size for paginated endpoints
  static const int defaultPageSize = 20;

  /// Maximum file upload size (10MB)
  static const int maxFileUploadBytes = 10 * 1024 * 1024;

  // ─────────────────────────────────────────────────────────────────────────────
  // Authentication Headers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Standard Bearer token header format
  static const String bearerTokenFormat = 'Bearer {token}';

  /// JWT claim for user ID
  static const String userIdClaim = 'user_id';
}
