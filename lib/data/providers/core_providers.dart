import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/network/api_client.dart';

// ---------------------------------------------------------------------------
// SharedPreferences — overridden at app startup in main.dart
// ---------------------------------------------------------------------------
final sharedPreferencesProvider = Provider<SharedPreferences>(
      (ref) => throw UnimplementedError('Override sharedPreferencesProvider in ProviderScope'),
);

// ---------------------------------------------------------------------------
// FlutterSecureStorage — low-level encrypted storage
// ---------------------------------------------------------------------------
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
      (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

// ---------------------------------------------------------------------------
// SecureStorage — unified auth + prefs wrapper
// ---------------------------------------------------------------------------
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final secure = ref.watch(flutterSecureStorageProvider);
  final prefs  = ref.watch(sharedPreferencesProvider);
  return SecureStorage(secure, prefs);
});

// ---------------------------------------------------------------------------
// ApiClient — single HTTP client used everywhere in the app
// ---------------------------------------------------------------------------
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});