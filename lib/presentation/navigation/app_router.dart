import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/verify_email_screen.dart';

// Shell screens
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/financial/financial_screen.dart';
import '../screens/profile/profile_screen.dart';

// Profile / settings
import '../screens/profile/profile_edit_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/two_factor_setup_screen.dart';
import '../screens/settings/two_factor_disable_screen.dart';

// Financial
import '../screens/financial/deposit_form_screen.dart';

// Notifications
import '../screens/notifications/notifications_screen.dart';

// Documents
import '../screens/documents/document_list_screen.dart';
import '../screens/documents/document_upload_screen.dart';

// Applications
import '../screens/applications/application_list_screen.dart';
import '../screens/applications/application_form_screen.dart';

// Beneficiaries
import '../screens/beneficiary/beneficiary_list_screen.dart';
import '../screens/beneficiary/beneficiary_form_screen.dart';

// Admin
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_deposit_approvals_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/admin_applications_screen.dart';
import '../screens/admin/admin_members_screen.dart';
import '../screens/admin/beneficiary_verification_screen.dart';

// Debug
import '../screens/debug/network_diagnostic_screen.dart';

// Info pages
import '../screens/info/info_screen.dart';

import 'main_shell.dart';

/// Notifies go_router to re-run its `redirect` callback whenever auth state
/// changes, without rebuilding the GoRouter instance itself (recreating the
/// router on every auth change loses navigation state and can leave the app
/// stuck on the current screen after login).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final _authRefreshNotifierProvider = Provider<_AuthRefreshNotifier>((ref) {
  final notifier = _AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_authRefreshNotifierProvider);

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isBootstrapping = authState.isBootstrapping;
      final loc = state.matchedLocation;

      if (isBootstrapping) return loc == '/' ? null : '/';

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/forgot-password') ||
          loc.startsWith('/otp') ||
          loc.startsWith('/verify-email');
      final isSplash = loc == '/';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && (isAuthRoute || isSplash)) return '/dashboard';
      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      // ── Auth ────────────────────────────────────────────────────────────────
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
      GoRoute(
        path: '/verify-email',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // ── Main shell (bottom nav) ──────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/financial',  builder: (_, __) => const FinancialScreen()),
          GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Profile ─────────────────────────────────────────────────────────────
      GoRoute(path: '/profile/edit',            builder: (_, __) => const ProfileEditScreen()),
      GoRoute(path: '/profile/change-password', builder: (_, __) => const ChangePasswordScreen()),

      // ── Settings ────────────────────────────────────────────────────────────
      GoRoute(path: '/settings',                  builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/change-password',  builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: '/settings/two-factor',       builder: (_, __) => const TwoFactorSetupScreen()),
      GoRoute(path: '/settings/two-factor-disable', builder: (_, __) => const TwoFactorDisableScreen()),

      // ── Financial ────────────────────────────────────────────────────────────
      GoRoute(path: '/deposit/new',  builder: (_, __) => const DepositFormScreen()),
      // /deposits mirrors /financial (used by the drawer)
      GoRoute(path: '/deposits',     builder: (_, __) => const FinancialScreen()),

      // ── Notifications ────────────────────────────────────────────────────────
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

      // ── Documents ────────────────────────────────────────────────────────────
      GoRoute(path: '/documents',        builder: (_, __) => const DocumentListScreen()),
      GoRoute(path: '/documents/upload', builder: (_, __) => const DocumentUploadScreen()),

      // ── Applications ─────────────────────────────────────────────────────────
      GoRoute(path: '/applications',     builder: (_, __) => const ApplicationListScreen()),
      GoRoute(path: '/applications/new', builder: (_, __) => const ApplicationFormScreen()),

      // ── Beneficiaries ────────────────────────────────────────────────────────
      GoRoute(path: '/beneficiaries',     builder: (_, __) => const BeneficiaryListScreen()),
      GoRoute(path: '/beneficiaries/add', builder: (_, __) => const BeneficiaryFormScreen()),

      // ── Admin ────────────────────────────────────────────────────────────────
      GoRoute(path: '/admin/dashboard',                 builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/deposits',                  builder: (_, __) => const AdminDepositApprovalsScreen()),
      GoRoute(path: '/admin/pending',                   builder: (_, __) => const AdminDepositApprovalsScreen()),
      GoRoute(path: '/admin/analytics',                 builder: (_, __) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/applications',              builder: (_, __) => const AdminApplicationsScreen()),
      GoRoute(path: '/admin/members',                   builder: (_, __) => const AdminMembersScreen()),
      GoRoute(path: '/admin/beneficiary-verification',  builder: (_, __) => const BeneficiaryVerificationScreen()),

      // ── Info ─────────────────────────────────────────────────────────────────
      GoRoute(path: '/privacy', builder: (_, __) => InfoScreen.privacy()),
      GoRoute(path: '/terms',   builder: (_, __) => InfoScreen.terms()),
      GoRoute(path: '/support', builder: (_, __) => InfoScreen.support()),

      // ── Debug ─────────────────────────────────────────────────────────────────
      GoRoute(path: '/debug/network', builder: (_, __) => const NetworkDiagnosticScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
