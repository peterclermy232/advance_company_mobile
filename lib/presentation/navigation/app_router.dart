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
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/beneficiary_verification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.location.startsWith('/login') ||
          state.location.startsWith('/register') ||
          state.location.startsWith('/forgot-password');

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

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
  );
});