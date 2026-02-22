import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/financial/financial_screen.dart';
import '../screens/financial/deposit_form_screen.dart';
import '../screens/financial/deposit_history_screen.dart';
import '../screens/beneficiary/beneficiary_list_screen.dart';
import '../screens/beneficiary/beneficiary_form_screen.dart';
import '../screens/documents/document_list_screen.dart';
import '../screens/documents/document_upload_screen.dart';
import '../screens/applications/application_list_screen.dart';
import '../screens/applications/application_form_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/admin_deposit_approvals_screen.dart';
import '../screens/admin/admin_members_screen.dart';
import '../screens/admin/admin_applications_screen.dart';   // ← NEW
import '../screens/admin/beneficiary_verification_screen.dart';
import '../screens/debug/network_diagnostic_screen.dart';

// ── Router Notifier ──────────────────────────────────────────────────────────

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
      (ref) => _RouterNotifier(ref),
);

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(currentUserProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// ── Router ───────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(currentUserProvider);

      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final location = state.uri.toString();

      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
      ];

      final isPublic = publicRoutes.any((r) => location.startsWith(r));

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
          token: state.uri.queryParameters['token'],
        ),
      ),

      // ── Main App ─────────────────────────────────────────────────────────
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/financial', builder: (_, __) => const FinancialScreen()),
      GoRoute(path: '/deposit-form', builder: (_, __) => const DepositFormScreen()),
      GoRoute(path: '/deposit-history', builder: (_, __) => const DepositHistoryScreen()),
      GoRoute(path: '/beneficiaries', builder: (_, __) => const BeneficiaryListScreen()),
      GoRoute(path: '/beneficiaries/add', builder: (_, __) => const BeneficiaryFormScreen()),
      GoRoute(path: '/documents', builder: (_, __) => const DocumentListScreen()),
      GoRoute(path: '/document-upload', builder: (_, __) => const DocumentUploadScreen()),
      GoRoute(path: '/applications', builder: (_, __) => const ApplicationListScreen()),
      GoRoute(path: '/applications/new', builder: (_, __) => const ApplicationFormScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/deposit-approvals', builder: (_, __) => const AdminDepositApprovalsScreen()),
      GoRoute(path: '/admin/beneficiary-verification', builder: (_, __) => const BeneficiaryVerificationScreen()),
      GoRoute(path: '/admin/members', builder: (_, __) => const AdminMembersScreen()),
      GoRoute(path: '/admin/applications', builder: (_, __) => const AdminApplicationsScreen()), // ← NEW

      GoRoute(path: '/debug/network', builder: (_, __) => const NetworkDiagnosticScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(),
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});