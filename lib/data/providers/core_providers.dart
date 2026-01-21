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

// SharedPreferences provider - FutureProvider instead of Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// SecureStorage provider - now properly handles async SharedPreferences
final secureStorageProvider = FutureProvider<SecureStorage>((ref) async {
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SecureStorage(secureStorage, prefs);
});

// ApiClient provider - now async
final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final storage = await ref.watch(secureStorageProvider.future);
  return ApiClient(storage);
});