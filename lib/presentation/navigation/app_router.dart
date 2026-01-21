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
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/beneficiary_verification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Handle loading state
      if (authState.isLoading) {
        return null; // Let the app show loading
      }

      final isLoggedIn = authState.value != null;
      final location = state.uri.toString();

      // Public routes that don't require authentication
      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
      ];

      final isPublicRoute =
          publicRoutes.any((route) => location.startsWith(route));

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // If logged in and trying to access public route, redirect to dashboard
      if (isLoggedIn && isPublicRoute) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth routes
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

      // Main routes
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

      // Admin routes
      GoRoute(
        path: '/admin/beneficiary-verification',
        builder: (context, state) => const BeneficiaryVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
