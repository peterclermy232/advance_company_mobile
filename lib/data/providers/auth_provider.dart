import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'core_providers.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

// ── State ──────────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool requires2FA;
  final String? tempToken;
  final String? twoFactorEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.requires2FA = false,
    this.tempToken,
    this.twoFactorEmail,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? requires2FA,
    String? tempToken,
    String? twoFactorEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requires2FA: requires2FA ?? this.requires2FA,
      tempToken: tempToken ?? this.tempToken,
      twoFactorEmail: twoFactorEmail ?? this.twoFactorEmail,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState(isLoading: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _repository.getStoredToken();
    if (token != null && token.isNotEmpty) {
      try {
        final user = await _repository.getProfile();
        state = AuthState(user: user, isAuthenticated: true);
      } catch (_) {
        state = const AuthState();
      }
    } else {
      state = const AuthState();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null, requires2FA: false);
    try {
      final result = await _repository.login(email: email, password: password);
      if (result.status == LoginStatus.twoFactorRequired) {
        state = state.copyWith(
          isLoading: false,
          requires2FA: true,
          tempToken: result.tempToken,
          twoFactorEmail: result.email ?? email,
        );
        return true;
      }
      state = AuthState(user: result.user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void complete2FA(UserModel user) {
    state = AuthState(user: user, isAuthenticated: true);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    state = const AuthState(isAuthenticated: false);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repository.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.updateProfile(data);
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ── Providers ──────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});