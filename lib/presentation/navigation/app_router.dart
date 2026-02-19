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
import '../screens/admin/beneficiary_verification_screen.dart';

// ✅ Step 1: RouterNotifier lives as its own provider — created once, never recreated
final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
      (ref) => _RouterNotifier(ref),
);

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // ✅ Listens to auth state changes and pings GoRouter to re-run redirect
    _ref.listen<AsyncValue>(currentUserProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// ✅ Step 2: GoRouter is created once — uses refreshListenable, not ref.watch
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier, // ✅ This replaces ref.watch — safe & correct
    redirect: (context, state) {
      final authState = ref.read(currentUserProvider); // ✅ read, not watch

      // Don't redirect while loading (initial app boot)
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final location = state.uri.toString();

      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
      ];

      final isPublicRoute =
      publicRoutes.any((route) => location.startsWith(route));

      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && isPublicRoute) return '/dashboard';

      return null;
    },
    routes: [
      // ═══════════════════════════════════════════
      // AUTH ROUTES
      // ═══════════════════════════════════════════
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
          token: state.uri.queryParameters['token'],
        ),
      ),

      // ═══════════════════════════════════════════
      // MAIN APP ROUTES
      // ═══════════════════════════════════════════
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/financial',
        builder: (context, state) => const FinancialScreen(),
      ),
      GoRoute(
        path: '/deposit-form',
        builder: (context, state) => const DepositFormScreen(),
      ),
      GoRoute(
        path: '/deposit-history',
        builder: (context, state) => const DepositHistoryScreen(),
      ),
      GoRoute(
        path: '/beneficiaries',
        builder: (context, state) => const BeneficiaryListScreen(),
      ),
      GoRoute(
        path: '/beneficiaries/add',
        builder: (context, state) => const BeneficiaryFormScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentListScreen(),
      ),
      GoRoute(
        path: '/document-upload',
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationListScreen(),
      ),
      GoRoute(
        path: '/applications/new',
        builder: (context, state) => const ApplicationFormScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // ═══════════════════════════════════════════
      // ADMIN ROUTES
      // ═══════════════════════════════════════════
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/deposit-approvals',
        builder: (context, state) => const AdminDepositApprovalsScreen(),
      ),
      GoRoute(
        path: '/admin/beneficiary-verification',
        builder: (context, state) => const BeneficiaryVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/members',
        builder: (context, state) => const AdminMembersScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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