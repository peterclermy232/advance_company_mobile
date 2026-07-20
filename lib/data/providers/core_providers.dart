import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/network/api_client.dart';
import '../services/auth_service.dart';
import '../services/financial_service.dart';
import '../services/beneficiary_service.dart';
import '../services/document_service.dart';
import '../services/application_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/admin_service.dart';
import '../services/health_service.dart';

// ---------------------------------------------------------------------------
// SharedPreferences — overridden at app startup in main.dart
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
      'Override sharedPreferencesProvider in ProviderScope'),
);

// ---------------------------------------------------------------------------
// FlutterSecureStorage — low-level encrypted storage
// ---------------------------------------------------------------------------
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // The data protection keychain requires a Keychain Sharing entitlement
    // tied to a real Apple Development Team, which this project's local/CI
    // ad-hoc signing doesn't have. Falling back to the legacy keychain avoids
    // needing that entitlement.
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  ),
);

// ---------------------------------------------------------------------------
// SecureStorage — unified auth + prefs wrapper
// ---------------------------------------------------------------------------
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final secure = ref.watch(flutterSecureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureStorage(secure, prefs);
});

// ---------------------------------------------------------------------------
// ApiClient — single HTTP client used everywhere in the app
// ---------------------------------------------------------------------------
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

// ---------------------------------------------------------------------------
// API Services — Domain-specific service layer
// Aligned with backend Django REST Framework modules
// ---------------------------------------------------------------------------

/// Authentication service - login, register, 2FA, biometrics, profile
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient: apiClient);
});

/// Financial service - accounts, deposits, interest
final financialServiceProvider = Provider<FinancialService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FinancialService(apiClient: apiClient);
});

/// Beneficiary service - CRUD and verification
final beneficiaryServiceProvider = Provider<BeneficiaryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BeneficiaryService(apiClient: apiClient);
});

/// Document service - uploads and verification
final documentServiceProvider = Provider<DocumentService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentService(apiClient: apiClient);
});

/// Application service - submission and admin review
final applicationServiceProvider = Provider<ApplicationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApplicationService(apiClient: apiClient);
});

/// Notification service - retrieval and management
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient: apiClient);
});

/// Report service - generation and analytics
final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportService(apiClient: apiClient);
});

/// Admin service - analytics and management (admin only)
final adminServiceProvider = Provider<AdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminService(apiClient: apiClient);
});

/// Health service - health checks and metrics
final healthServiceProvider = Provider<HealthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthService(apiClient: apiClient);
});
