// lib/data/models/user_model.dart

class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'admin' | 'member' | 'staff'
  final bool isEmailVerified;
  final bool isBiometricEnabled;
  final String? profileImageUrl;
  final String? phoneNumber;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isEmailVerified,
    required this.isBiometricEnabled,
    required this.createdAt,
    this.profileImageUrl,
    this.phoneNumber,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:                  json['id'] as int,
      email:               json['email'] as String,
      firstName:           json['first_name'] as String? ?? '',
      lastName:            json['last_name'] as String? ?? '',
      role:                json['role'] as String? ?? 'member',
      isEmailVerified:     json['is_email_verified'] as bool? ?? false,
      isBiometricEnabled:  json['is_biometric_enabled'] as bool? ?? false,
      profileImageUrl:     json['profile_image'] as String?,
      phoneNumber:         json['phone_number'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'is_email_verified': isEmailVerified,
    'is_biometric_enabled': isBiometricEnabled,
    'profile_image': profileImageUrl,
    'phone_number': phoneNumber,
  };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isBiometricEnabled,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      isEmailVerified: isEmailVerified,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
    );
  }
}