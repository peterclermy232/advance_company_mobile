// lib/presentation/navigation/app_router.dart
//
// Uses go_router with auth-based redirects.
// • Unauthenticated users → /login
// • Authenticated users trying to access /login → /dashboard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/financial/financial_screen.dart';
import '../screens/financial/deposit_form_screen.dart';
import '../screens/admin/admin_deposit_approvals_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',        builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return OtpScreen(email: email);
        },
      ),

      // ── Main shell (bottom nav) ────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/financial',  builder: (_, __) => const FinancialScreen()),
          GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Standalone routes (no bottom nav) ─────────────────────────────────
      GoRoute(path: '/deposit/new', builder: (_, __) => const DepositFormScreen()),
      GoRoute(path: '/admin/deposits', builder: (_, __) => const AdminDepositApprovalsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});