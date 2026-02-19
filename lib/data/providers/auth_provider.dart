import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'core_providers.dart';

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final storage = await ref.watch(secureStorageProvider.future);
  return AuthRepository(apiClient, storage);
});

final currentUserProvider =
StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>(
      (ref) => UserNotifier(ref),
);

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;

  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final user = await authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      // ✅ If no session found, set null (not error) so router goes to /login cleanly
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final authResponse = await authRepository.login(email, password);
      // ✅ This triggers GoRouter redirect → /dashboard
      state = AsyncValue.data(authResponse.user);
    } catch (e, stack) {
      // ✅ On error, reset to null (not error state) so router stays on /login
      state = const AsyncValue.data(null);
      // ✅ Still rethrow so LoginScreen can show the SnackBar
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final authResponse = await authRepository.register(data);
      state = AsyncValue.data(authResponse.user);
    } catch (e, stack) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      await authRepository.logout();
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  Future<void> refreshUser() async {
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final user = await authRepository.getUserProfile();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(int userId, Map<String, dynamic> data) async {
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final user = await authRepository.updateProfile(userId, data);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}