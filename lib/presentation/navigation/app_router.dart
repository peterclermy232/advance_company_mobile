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
    debugLogDiagnostics: true, // Enable for debugging

    redirect: (context, state) {
      // Handle loading state
      if (authState.isLoading) {
        return null; // Let the app show loading
      }

      final isLoggedIn = authState.value != null;
      final location = state.uri.toString();
      final path = state.uri.path;

      // Public routes that don't require authentication
      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
      ];

      final isPublicRoute = publicRoutes.any((route) => path.startsWith(route));

      // Deep link handling for email verification
      if (path == '/verify-email') {
        final email = state.uri.queryParameters['email'];
        final token = state.uri.queryParameters['token'];

        // Allow access to verify-email with valid parameters even if not logged in
        if (email != null && token != null) {
          return null; // Allow access
        }

        // If no valid parameters, redirect to login
        if (!isLoggedIn) {
          return '/login';
        }
      }

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // If logged in and trying to access public route (except verify-email), redirect to dashboard
      if (isLoggedIn && isPublicRoute && path != '/verify-email') {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },

    routes: [
      // ============================================================
      // AUTH ROUTES
      // ============================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
          token: state.uri.queryParameters['token'],
        ),
      ),

      // ============================================================
      // MAIN ROUTES
      // ============================================================
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ============================================================
      // FINANCIAL ROUTES
      // ============================================================
      GoRoute(
        path: '/financial',
        name: 'financial',
        builder: (context, state) => const FinancialScreen(),
      ),

      GoRoute(
        path: '/deposit-form',
        name: 'deposit-form',
        builder: (context, state) => const DepositFormScreen(),
      ),

      GoRoute(
        path: '/deposit-history',
        name: 'deposit-history',
        builder: (context, state) => const DepositHistoryScreen(),
      ),

      // ============================================================
      // BENEFICIARY ROUTES
      // ============================================================
      GoRoute(
        path: '/beneficiaries',
        name: 'beneficiaries',
        builder: (context, state) => const BeneficiaryListScreen(),
      ),

      GoRoute(
        path: '/beneficiaries/add',
        name: 'beneficiaries-add',
        builder: (context, state) => const BeneficiaryFormScreen(),
      ),

      // ============================================================
      // DOCUMENT ROUTES
      // ============================================================
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentListScreen(),
      ),

      GoRoute(
        path: '/document-upload',
        name: 'document-upload',
        builder: (context, state) => const DocumentUploadScreen(),
      ),

      // ============================================================
      // APPLICATION ROUTES
      // ============================================================
      GoRoute(
        path: '/applications',
        name: 'applications',
        builder: (context, state) => const ApplicationListScreen(),
      ),

      GoRoute(
        path: '/applications/new',
        name: 'applications-new',
        builder: (context, state) => const ApplicationFormScreen(),
      ),

      // ============================================================
      // NOTIFICATION ROUTES
      // ============================================================
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ============================================================
      // SETTINGS ROUTES
      // ============================================================
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ============================================================
      // ADMIN ROUTES
      // ============================================================
      GoRoute(
        path: '/admin/beneficiary-verification',
        name: 'admin-beneficiary-verification',
        builder: (context, state) => const BeneficiaryVerificationScreen(),
      ),

      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
    ],

    // ============================================================
    // ERROR HANDLING
    // ============================================================
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.uri.path}" does not exist.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});