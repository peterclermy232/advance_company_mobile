
class AppConfig {
  // App Information
  static const String appName = 'Advance Company';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  // Company Information
  static const String companyName = 'Advance Company';
  static const String supportEmail = 'support@advancecompany.com';
  static const String supportPhone = '+254 712 345 678';
  
  // Feature Flags
  static const bool enableBiometrics = true;
  static const bool enable2FA = true;
  static const bool enableNotifications = true;
  static const bool enableFileUpload = true;
  
  // Limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxBeneficiaries = 10;
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Duration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(hours: 8);
  
  // UI Configuration
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultCardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}