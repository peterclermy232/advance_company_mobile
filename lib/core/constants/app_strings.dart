// ============================================
// lib/core/constants/app_strings.dart
// ============================================
class AppStrings {
  // App
  static const String appName = 'Advance Company';
  static const String appVersion = '1.0.0';

  // Error Messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'No internet connection.';
  static const String errorTimeout = 'Request timeout. Please try again.';
  static const String errorUnauthorized = 'Unauthorized. Please login again.';
  static const String errorNotFound = 'Resource not found.';
  static const String errorServer = 'Server error. Please try again later.';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successRegister = 'Registration successful!';
  static const String successUpdate = 'Updated successfully!';
  static const String successDelete = 'Deleted successfully!';

  // Validation Messages
  static const String validationRequired = 'This field is required';
  static const String validationEmail = 'Enter a valid email address';
  static const String validationPassword = 'Password must be at least 12 characters';
  static const String validationPasswordMatch = 'Passwords do not match';
  static const String validationPhone = 'Enter a valid phone number';
}