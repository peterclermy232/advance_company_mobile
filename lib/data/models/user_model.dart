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

  // ✅ Safe date parser
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return DateTime.now();
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // API returns uuid string, fallback to 0
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      // API doesn't return first_name/last_name, derive from full_name
      firstName: json['first_name'] ?? (json['full_name'] as String? ?? '').split(' ').first,
      lastName: json['last_name'] ?? (json['full_name'] as String? ?? '').split(' ').skip(1).join(' '),
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'],
      age: json['age'],
      gender: json['gender'],
      maritalStatus: json['marital_status'],
      profession: json['profession'],
      profilePhoto: json['profile_photo'],
      profilePhotoUrl: json['profile_photo_url'],
      // API doesn't return date_joined, use created_at
      dateJoined: _parseDate(json['date_joined'] ?? json['created_at']),
      lastLogin: json['last_login'] != null ? _parseDate(json['last_login']) : null,
      // API doesn't return is_active, derive from activity_status
      isActive: json['is_active'] ?? (json['activity_status'] == 'Active'),
      // API doesn't return is_staff, derive from role
      isStaff: json['is_staff'] ?? (json['role'] == 'admin'),
      isSuperuser: json['is_superuser'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      biometricEnabled: json['biometric_enabled'] ?? false,
      role: json['role'],
      activityStatus: json['activity_status'] ?? 'Active',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
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
    id, email, firstName, lastName, fullName, phoneNumber, age, gender,
    maritalStatus, profession, profilePhoto, profilePhotoUrl, dateJoined,
    lastLogin, isActive, isStaff, isSuperuser, emailVerified,
    twoFactorEnabled, biometricEnabled, role, activityStatus,
    createdAt, updatedAt,
  ];
}