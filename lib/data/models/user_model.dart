// ============================================
// lib/data/models/user_model.dart
// ============================================
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phoneNumber;
  final int? age;
  final String? gender;
  final String? maritalStatus;
  final String? profession;
  final String? profilePhoto;
  final String? profilePhotoUrl;
  final DateTime dateJoined;
  final DateTime? lastLogin;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final bool emailVerified;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final String? role;
  final String activityStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phoneNumber,
    this.age,
    this.gender,
    this.maritalStatus,
    this.profession,
    this.profilePhoto,
    this.profilePhotoUrl,
    required this.dateJoined,
    this.lastLogin,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    required this.emailVerified,
    required this.twoFactorEnabled,
    required this.biometricEnabled,
    this.role,
    required this.activityStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      profession: json['profession'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      dateJoined: DateTime.parse(json['date_joined'] as String),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      isActive: json['is_active'] as bool,
      isStaff: json['is_staff'] as bool,
      isSuperuser: json['is_superuser'] as bool,
      emailVerified: json['email_verified'] as bool,
      twoFactorEnabled: json['two_factor_enabled'] as bool,
      biometricEnabled: json['biometric_enabled'] as bool,
      role: json['role'] as String?,
      activityStatus: json['activity_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'age': age,
      'gender': gender,
      'marital_status': maritalStatus,
      'profession': profession,
      'profile_photo': profilePhoto,
      'profile_photo_url': profilePhotoUrl,
      'date_joined': dateJoined.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'email_verified': emailVerified,
      'two_factor_enabled': twoFactorEnabled,
      'biometric_enabled': biometricEnabled,
      'role': role,
      'activity_status': activityStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin' || isStaff;

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        fullName,
        phoneNumber,
        age,
        gender,
        maritalStatus,
        profession,
        profilePhoto,
        profilePhotoUrl,
        dateJoined,
        lastLogin,
        isActive,
        isStaff,
        isSuperuser,
        emailVerified,
        twoFactorEnabled,
        biometricEnabled,
        role,
        activityStatus,
        createdAt,
        updatedAt,
      ];
}