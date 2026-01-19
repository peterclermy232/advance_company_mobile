// ============================================
// lib/data/models/beneficiary_model.dart
// ============================================
class BeneficiaryModel extends Equatable {
  final int id;
  final int user;
  final String? userName;
  final String name;
  final String relation;
  final int age;
  final String gender;
  final String? phoneNumber;
  final String? profession;
  final String? salaryRange;
  final String? identityDocument;
  final String? birthCertificate;
  final String? deathCertificate;
  final String? deathCertificateNumber;
  final String? additionalDocuments;
  final String status;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BeneficiaryModel({
    required this.id,
    required this.user,
    this.userName,
    required this.name,
    required this.relation,
    required this.age,
    required this.gender,
    this.phoneNumber,
    this.profession,
    this.salaryRange,
    this.identityDocument,
    this.birthCertificate,
    this.deathCertificate,
    this.deathCertificateNumber,
    this.additionalDocuments,
    required this.status,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userName: json['user_name'] as String?,
      name: json['name'] as String,
      relation: json['relation'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      phoneNumber: json['phone_number'] as String?,
      profession: json['profession'] as String?,
      salaryRange: json['salary_range'] as String?,
      identityDocument: json['identity_document'] as String?,
      birthCertificate: json['birth_certificate'] as String?,
      deathCertificate: json['death_certificate'] as String?,
      deathCertificateNumber: json['death_certificate_number'] as String?,
      additionalDocuments: json['additional_documents'] as String?,
      status: json['status'] as String,
      verificationStatus: json['verification_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        user,
        userName,
        name,
        relation,
        age,
        gender,
        phoneNumber,
        profession,
        status,
        verificationStatus,
        createdAt,
        updatedAt,
      ];
}