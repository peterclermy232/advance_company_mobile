// lib/config/api_config.dart

class ApiConfig {
  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Set the correct URL for your environment
  // ════════════════════════════════════════════════════════════════════════════
  //
  //  ┌─────────────────────────────┬──────────────────────────────────────────┐
  //  │ You are running on…         │ Use this devBaseUrl                       │
  //  ├─────────────────────────────┼──────────────────────────────────────────┤
  //  │ Android Emulator            │ http://10.0.2.2:8000/api                 │
  //  │ iOS Simulator               │ http://127.0.0.1:8000/api                │
  //  │ Physical Android/iOS device │ http://<YOUR_PC_LAN_IP>:8000/api         │
  //  │   → find LAN IP:            │   Windows: ipconfig → IPv4 Address        │
  //  │                             │   Mac/Linux: ifconfig | grep 'inet '     │
  //  │                             │   e.g. http://192.168.1.45:8000/api      │
  //  └─────────────────────────────┴──────────────────────────────────────────┘
  //
  //  ⚠️  Physical device REQUIREMENT: start Django with
  //      python manage.py runserver 0.0.0.0:8000
  //      (NOT just 127.0.0.1 — the device can't reach that)
  //
  //  ⚠️  Both your PC and device must be on the SAME Wi-Fi network.
  //
  // ════════════════════════════════════════════════════════════════════════════

  /// Production server (set this before release)
  static const String prodBaseUrl = 'https://YOUR_PRODUCTION_DOMAIN/api';

  /// Development server — change to match YOUR setup (see table above)
  static const String devBaseUrl = 'http://127.0.0.1:8000/api';
  //                                          ↑
  //   Android Emulator default. Change to your LAN IP for a physical device.

  /// Flip to true when building a production release
  static const bool _isProduction = false;

  static String get baseUrl => _isProduction ? prodBaseUrl : devBaseUrl;

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2 — Timeouts
  // ════════════════════════════════════════════════════════════════════════════
  //
  //  connectTimeout → how long to wait while establishing the TCP connection.
  //  If you get DioExceptionType.connectionTimeout it means the IP/port is
  //  wrong or the server is not running — not a slow server.
  //
  //  receiveTimeout → how long to wait for the server to send back data once
  //  the connection is open. Raise this for slow APIs.
  //
  // ════════════════════════════════════════════════════════════════════════════

  /// Raised to 15 s — if connection still times out the URL is simply wrong.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// 30 s is plenty for most responses.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// 60 s for file/document uploads.
  static const Duration sendTimeout = Duration(seconds: 60);
}