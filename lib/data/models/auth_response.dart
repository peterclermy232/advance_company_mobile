// ============================================
// lib/data/models/auth_response.dart
// ============================================
import 'user_model.dart';
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String? message;
  final bool? requires2FA;
  final String? tempToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.message,
    this.requires2FA,
    this.tempToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['tokens']['access'] as String,
      refreshToken: json['tokens']['refresh'] as String,
      message: json['message'] as String?,
      requires2FA: json['requires_2fa'] as bool?,
      tempToken: json['temp_token'] as String?,
    );
  }
}