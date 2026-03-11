
class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'admin' | 'member' | 'staff'
  final bool isEmailVerified;
  final bool isBiometricEnabled;
  final bool twoFactorEnabled;
  final String? profileImageUrl;
  // Alias for profileImageUrl used in profile screens
  String? get profilePhotoUrl => profileImageUrl;
  final String? phoneNumber;
  final String? profession;
  final int? age;
  final String? gender;
  final String? maritalStatus;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isEmailVerified,
    required this.isBiometricEnabled,
    this.twoFactorEnabled = false,
    required this.createdAt,
    this.profileImageUrl,
    this.phoneNumber,
    this.profession,
    this.age,
    this.gender,
    this.maritalStatus,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get biometricEnabled => isBiometricEnabled;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isBiometricEnabled: json['is_biometric_enabled'] as bool? ?? false,
      twoFactorEnabled: json['two_factor_enabled'] as bool? ??
          json['is_2fa_enabled'] as bool? ?? false,
      profileImageUrl: json['profile_image'] as String? ??
          json['profile_photo'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profession: json['profession'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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
    'two_factor_enabled': twoFactorEnabled,
    'profile_image': profileImageUrl,
    'phone_number': phoneNumber,
    'profession': profession,
    'age': age,
    'gender': gender,
    'marital_status': maritalStatus,
  };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isBiometricEnabled,
    bool? twoFactorEnabled,
    String? profession,
    int? age,
    String? gender,
    String? maritalStatus,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      isEmailVerified: isEmailVerified,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profession: profession ?? this.profession,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      createdAt: createdAt,
    );
  }
}