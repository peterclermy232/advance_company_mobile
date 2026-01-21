import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// FlutterSecureStorage provider
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

// SharedPreferences provider - properly async
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// SecureStorage provider - handles the async dependency properly
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  
  // Return a dummy instance while loading, or throw if error
  return prefsAsync.when(
    data: (prefs) => SecureStorage(secureStorage, prefs),
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stack) => throw error,
  );
});

// ApiClient provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});