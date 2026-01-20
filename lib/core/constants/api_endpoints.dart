
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
  
  // Financial Endpoints
  static const String myAccount = '/financial/accounts/my_account/';
  static const String deposits = '/financial/deposits/';
  static const String createDeposit = '/financial/deposits/';
  static const String canDeposit = '/financial/deposits/can_deposit/';
  static const String monthlySummary = '/financial/deposits/monthly_summary/';
  static const String pendingApprovals = '/financial/deposits/pending_approvals/';
  static String approveDeposit(int id) => '/financial/deposits/$id/approve_deposit/';
  static String rejectDeposit(int id) => '/financial/deposits/$id/reject_deposit/';
  
  // Beneficiary Endpoints
  static const String beneficiaries = '/beneficiary/';
  static String beneficiaryDetail(int id) => '/beneficiary/$id/';
  static String verifyBeneficiary(int id) => '/beneficiary/$id/verify/';
  static String markDeceased(int id) => '/beneficiary/$id/mark_deceased/';
  static const String beneficiaryStatistics = '/beneficiary/statistics/';
  
  // Document Endpoints
  static const String documents = '/documents/';
  static String documentDetail(int id) => '/documents/$id/';
  static String verifyDocument(int id) => '/documents/$id/verify/';
  static String rejectDocument(int id) => '/documents/$id/reject/';
  
  // Application Endpoints
  static const String applications = '/applications/';
  static String applicationDetail(int id) => '/applications/$id/';
  static String approveApplication(int id) => '/applications/$id/approve/';
  static String rejectApplication(int id) => '/applications/$id/reject/';
  static String reviewApplication(int id) => '/applications/$id/review/';
  
  // Notification Endpoints
  static const String notifications = '/notifications/';
  static const String unreadCount = '/notifications/unread_count/';
  static const String recentNotifications = '/notifications/recent/';
  static String markAsRead(int id) => '/notifications/$id/mark_as_read/';
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
