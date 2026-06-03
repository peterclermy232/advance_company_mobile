// lib/core/constants/api_endpoints.dart
// Aligned with backend API structure from backend documentation

class ApiEndpoints {
  // ─────────────────────────────────────────────────────────────────────────────
  // Auth Endpoints (Public & Protected)
  // ─────────────────────────────────────────────────────────────────────────────

  // Public Auth
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String verifyEmail = '/auth/verify-email/';
  static const String resendVerification = '/auth/resend-verification/';
  static const String verify2FA = '/auth/verify-2fa/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPasswordConfirm = '/auth/reset-password-confirm/';
  static const String refreshToken = '/token/refresh/';

  // Protected User Endpoints
  static const String users = '/auth/users/';
  static String userDetail(String uuid) => '/auth/users/$uuid/';
  static String updateUser(String uuid) => '/auth/users/$uuid/';
  static String deleteUser(String uuid) => '/auth/users/$uuid/';
  static const String changePassword = '/auth/users/change_password/';
  static const String enable2FA = '/auth/users/enable_2fa/';
  static const String confirm2FA = '/auth/users/confirm_2fa/';
  static const String disable2FA = '/auth/users/disable_2fa/';
  static const String regenerateBackupCodes =
      '/auth/users/regenerate_backup_codes/';
  static const String registerBiometric = '/auth/users/register_biometric/';
  static const String biometricDevices = '/auth/users/biometric_devices/';
  static String deleteBiometricDevice(String uuid, String deviceId) =>
      '/auth/users/$uuid/biometric-devices/$deviceId/';
  static const String deleteAccount = '/auth/users/delete_account/';
  static const String uploadProfilePhoto = '/auth/users/upload_profile_photo/';
  static const String deleteProfilePhoto = '/auth/users/delete_profile_photo/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Financial Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String accounts = '/financial/accounts/';
  static String accountDetail(String uuid) => '/financial/accounts/$uuid/';
  static const String myAccount = '/financial/accounts/my_account/';

  static const String deposits = '/financial/deposits/';
  static String depositDetail(String uuid) => '/financial/deposits/$uuid/';
  static const String canDeposit = '/financial/deposits/can_deposit/';
  static const String monthlySummary = '/financial/deposits/monthly_summary/';
  static const String pendingApprovals =
      '/financial/deposits/pending_approvals/';
  static String approveDeposit(String uuid) =>
      '/financial/deposits/$uuid/approve_deposit/';
  static String rejectDeposit(String uuid) =>
      '/financial/deposits/$uuid/reject_deposit/';

  static const String interest = '/financial/interest/';
  static String interestDetail(String uuid) => '/financial/interest/$uuid/';

  static const String mpesaCallback = '/financial/mpesa/callback/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Beneficiary Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String beneficiaries = '/beneficiary/';
  static String beneficiaryDetail(String uuid) => '/beneficiary/$uuid/';
  static String updateBeneficiary(String uuid) => '/beneficiary/$uuid/';
  static String deleteBeneficiary(String uuid) => '/beneficiary/$uuid/';
  static String verifyBeneficiary(String uuid) => '/beneficiary/$uuid/verify/';
  static String rejectBeneficiary(String uuid) => '/beneficiary/$uuid/reject/';
  static String markDeceased(String uuid) =>
      '/beneficiary/$uuid/mark_deceased/';
  static const String pendingVerification =
      '/beneficiary/pending_verification/';
  static const String beneficiaryStatistics = '/beneficiary/statistics/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Document Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String documents = '/documents/';
  static String documentDetail(String uuid) => '/documents/$uuid/';
  static String updateDocument(String uuid) => '/documents/$uuid/';
  static String deleteDocument(String uuid) => '/documents/$uuid/';
  static String getDocumentViewUrl(String uuid) => '/documents/$uuid/view_url/';
  static String verifyDocument(String uuid) => '/documents/$uuid/verify/';
  static String rejectDocument(String uuid) => '/documents/$uuid/reject/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Application Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String applications = '/applications/';
  static String applicationDetail(String id) => '/applications/$id/';
  static String updateApplication(String id) => '/applications/$id/';
  static String deleteApplication(String id) => '/applications/$id/';
  static const String applicationChoices = '/applications/choices/';
  static String approveApplication(String id) => '/applications/$id/approve/';
  static String rejectApplication(String id) => '/applications/$id/reject/';
  static String reviewApplication(String id) => '/applications/$id/review/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Report Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String reports = '/reports/';
  static String reportDetail(String uuid) => '/reports/$uuid/';
  static const String generateFinancialReport =
      '/reports/generate_financial_report/';
  static const String generateCompensatoryReport =
      '/reports/generate_compensatory_report/';
  static const String generateActivityReport =
      '/reports/generate_activity_report/';
  static String resendReportEmail(String uuid) =>
      '/reports/$uuid/resend_report_email/';
  static const String dashboardSummary = '/reports/dashboard_summary/';
  static const String reportSummary = '/reports/summary/';
  static const String depositTrends = '/reports/deposit_trends/';
  static const String activityLogs = '/reports/activity-logs/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Notification Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String notifications = '/notifications/';
  static String notificationDetail(String uuid) => '/notifications/$uuid/';
  static const String unreadNotifications = '/notifications/unread/';
  static const String unreadCount = '/notifications/unread_count/';
  static const String recentNotifications = '/notifications/recent/';
  static String markAsRead(String uuid) => '/notifications/$uuid/mark_as_read/';
  static const String markAllAsRead = '/notifications/mark_all_as_read/';
  static String deleteNotification(String uuid) =>
      '/notifications/$uuid/delete_notification/';
  static const String clearAll = '/notifications/clear_all/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Admin Analytics Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String adminMembers = '/admin/analytics/members/';
  static const String adminSummary = '/admin/analytics/summary/';
  static const String adminExport = '/admin/analytics/export/';

  // ─────────────────────────────────────────────────────────────────────────────
  // Health Endpoints
  // ─────────────────────────────────────────────────────────────────────────────

  static const String health = '/health/';
  static const String metrics = '/health/metrics/';
}
