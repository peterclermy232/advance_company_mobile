class ApiEndpoints {
  // Auth Endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String logout = '/auth/logout/';
  static const String refreshToken = '/token/refresh/';
  static const String verifyEmail = '/auth/verify-email/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPassword = '/auth/reset-password-confirm/';
  static const String changePassword = '/auth/users/change_password/';
  static const String currentUser = '/auth/users/me/';
  static const String updateProfile = '/auth/users/{id}/';

  // 2FA Endpoints
  static const String enable2FA = '/auth/users/enable_2fa/';
  static const String confirm2FA = '/auth/users/confirm_2fa/';
  static const String disable2FA = '/auth/users/disable_2fa/';
  static const String verify2FA = '/auth/verify-2fa/';

  // Financial Endpoints  (deposit IDs are integers)
  static const String myAccount = '/financial/accounts/my_account/';
  static const String deposits = '/financial/deposits/';
  static const String createDeposit = '/financial/deposits/';
  static const String canDeposit = '/financial/deposits/can_deposit/';
  static const String monthlySummary = '/financial/deposits/monthly_summary/';
  static const String pendingApprovals = '/financial/deposits/pending_approvals/';
  static String approveDeposit(String id) => '/financial/deposits/$id/approve_deposit/';
  static String rejectDeposit(String id) => '/financial/deposits/$id/reject_deposit/';

  // Beneficiary Endpoints  (beneficiary IDs are integers)
  static const String beneficiaries = '/beneficiary/';
  static String beneficiaryDetail(String id) => '/beneficiary/$id/';
  static String verifyBeneficiary(String id) => '/beneficiary/$id/verify/';
  static String markDeceased(String id) => '/beneficiary/$id/mark_deceased/';
  static const String beneficiaryStatistics = '/beneficiary/statistics/';

  // Document Endpoints  (document IDs are integers)
  static const String documents = '/documents/';
  static String documentDetail(String id) => '/documents/$id/';
  static String verifyDocument(String id) => '/documents/$id/verify/';
  static String rejectDocument(String id) => '/documents/$id/reject/';

  // Application Endpoints  (application IDs are UUID *strings*)
  static const String applications = '/applications/';
  static const String applicationChoices = '/applications/choices/';
  static String applicationDetail(String id) => '/applications/$id/';
  static String approveApplication(String id) => '/applications/$id/approve/';
  static String rejectApplication(String id) => '/applications/$id/reject/';
  static String reviewApplication(String id) => '/applications/$id/review/';

  // Notification Endpoints  (notification IDs are integers)
  static const String notifications = '/notifications/';
  static const String unreadCount = '/notifications/unread_count/';
  static const String recentNotifications = '/notifications/recent/';
  static String markAsRead(String id) => '/notifications/$id/mark_as_read/';
  static const String markAllAsRead = '/notifications/mark_all_as_read/';
  static const String clearAll = '/notifications/clear_all/';

  // Report Endpoints
  static const String reports = '/reports/';
  static const String generateFinancialReport = '/reports/generate_financial_report/';
  static const String dashboardSummary = '/reports/dashboard_summary/';

  // Admin Endpoints
  static const String adminAnalytics = '/admin/analytics/members/';
  static const String analyticsSummary = '/admin/analytics/summary/';
  static const String monthlyTrends = '/admin/analytics/trends/';
  static const String exportAnalytics = '/admin/analytics/export/';
}