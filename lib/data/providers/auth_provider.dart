// lib/data/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'core_providers.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final storage   = await ref.watch(secureStorageProvider.future);
  return AuthRepository(apiClient, storage);
});

// ── Auth state ───────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading        => status == AuthStatus.loading;
  bool get hasError         => error != null;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user:   user   ?? this.user,
      error:  error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = await ref.watch(secureStorageProvider.future);
    final hasSession = await storage.hasValidSession();

    if (!hasSession) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final user = await repo.getProfile();
      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await storage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? otpCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(authRepositoryProvider.future);
      final user = await repo.login(
        email: email,
        password: password,
        otpCode: otpCode,
      );
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.logout();
    } catch (_) {}
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> refreshProfile() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      final user = await repo.getProfile();
      state = AsyncData(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {}
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);