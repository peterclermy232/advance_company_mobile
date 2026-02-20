
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/network/api_client.dart';

// ── 1. FlutterSecureStorage ───────────────────────────────────────────────────

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ── 2. SharedPreferences  (async — initialised once in main.dart) ─────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider not initialised. '
        'Add sharedPreferencesProvider.overrideWithValue(prefs) in main.dart',
  );
});

// ── 3. SecureStorage ──────────────────────────────────────────────────────────
//  FutureProvider so callers can do: await ref.watch(secureStorageProvider.future)

final secureStorageProvider = FutureProvider<SecureStorage>((ref) async {
  final secure = ref.watch(flutterSecureStorageProvider);
  final prefs  = ref.watch(sharedPreferencesProvider); // sync after main.dart override
  return SecureStorage(secure, prefs);
});

// ── 4. ApiClient ──────────────────────────────────────────────────────────────
//  FutureProvider — matches every callsite: await ref.read(apiClientProvider.future)

final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final storage = await ref.watch(secureStorageProvider.future);
  return ApiClient(storage);
});