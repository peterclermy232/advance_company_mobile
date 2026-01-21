import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'core_providers.dart';

// Auth Repository Provider
final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final storage = await ref.watch(secureStorageProvider.future);
  return AuthRepository(apiClient, storage);
});

// Current User Provider
final currentUserProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;

  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final user = await authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = await _ref.read(authRepositoryProvider.future);
      final authResponse = await authRepository.login(email, password);
      state = AsyncValue.data(authResponse.user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    final authRepository = await _ref.read(authRepositoryProvider.future);
    await authRepository.logout();
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