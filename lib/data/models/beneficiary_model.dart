import 'package:equatable/equatable.dart';

class BeneficiaryModel extends Equatable {
  final String id;               // uuid (PK)
  final String user;             // uuid FK to User
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  final String name;
  final String relation;         // 'spouse'|'child'|'parent'|'sibling'|'other'
  final String? relationDisplay;
  final int age;
  final String gender;           // 'M'|'F'|'O'
  final String? genderDisplay;
  final String? phoneNumber;
  final String? profession;
  final String? salaryRange;
  final double percentageAllocation; // 0.00–100.00

  // Document paths (relative or presigned URLs from backend)
  final String? identityDocument;
  final String? identityDocumentUrl;
  final String? birthCertificate;
  final String? birthCertificateUrl;
  final String? deathCertificate;
  final String? deathCertificateUrl;
  final String? deathCertificateNumber;
  final String? additionalDocuments;
  final String? additionalDocumentsUrl;

  final String status;              // 'active'|'deceased'|'removed'
  final String? statusDisplay;
  final String verificationStatus;  // 'verified'|'pending'|'rejected'
  final String? verificationStatusDisplay;

  final DateTime createdAt;
  final DateTime updatedAt;

  const BeneficiaryModel({
    required this.id,
    required this.user,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.name,
    required this.relation,
    this.relationDisplay,
    required this.age,
    required this.gender,
    this.genderDisplay,
    this.phoneNumber,
    this.profession,
    this.salaryRange,
    this.percentageAllocation = 0.0,
    this.identityDocument,
    this.identityDocumentUrl,
    this.birthCertificate,
    this.birthCertificateUrl,
    this.deathCertificate,
    this.deathCertificateUrl,
    this.deathCertificateNumber,
    this.additionalDocuments,
    this.additionalDocumentsUrl,
    required this.status,
    this.statusDisplay,
    required this.verificationStatus,
    this.verificationStatusDisplay,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Status helpers ──────────────────────────────────────────────────────────

  bool get isActive       => status == 'active';
  bool get isDeceased     => status == 'deceased';
  bool get isRemoved      => status == 'removed';

  bool get isVerified     => verificationStatus == 'verified';
  bool get isPending      => verificationStatus == 'pending';
  bool get isRejected     => verificationStatus == 'rejected';

  // ── Factory ─────────────────────────────────────────────────────────────────

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      // Backend primary key is 'uuid'
      id:                        json['uuid'] as String,
      user:                      json['user'] as String,
      userName:                  json['user_name'] as String?,
      userEmail:                 json['user_email'] as String?,
      userPhone:                 json['user_phone'] as String?,

      name:                      json['name'] as String,
      relation:                  json['relation'] as String,
      relationDisplay:           json['relation_display'] as String?,
      age:                       json['age'] as int,
      gender:                    json['gender'] as String,
      genderDisplay:             json['gender_display'] as String?,
      phoneNumber:               json['phone_number'] as String?,
      profession:                json['profession'] as String?,
      salaryRange:               json['salary_range'] as String?,
      percentageAllocation: double.tryParse(
          json['percentage_allocation']?.toString() ?? '0') ??
          0.0,

      identityDocument:          json['identity_document'] as String?,
      identityDocumentUrl:       json['identity_document_url'] as String?,
      birthCertificate:          json['birth_certificate'] as String?,
      birthCertificateUrl:       json['birth_certificate_url'] as String?,
      deathCertificate:          json['death_certificate'] as String?,
      deathCertificateUrl:       json['death_certificate_url'] as String?,
      deathCertificateNumber:    json['death_certificate_number'] as String?,
      additionalDocuments:       json['additional_documents'] as String?,
      additionalDocumentsUrl:    json['additional_documents_url'] as String?,

      status:                    json['status'] as String? ?? 'active',
      statusDisplay:             json['status_display'] as String?,
      verificationStatus:        json['verification_status'] as String? ?? 'pending',
      verificationStatusDisplay: json['verification_status_display'] as String?,

      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': id,
    'user': user,
    'name': name,
    'relation': relation,
    'age': age,
    'gender': gender,
    'phone_number': phoneNumber,
    'profession': profession,
    'salary_range': salaryRange,
    'percentage_allocation': percentageAllocation,
    'status': status,
    'verification_status': verificationStatus,
  };

  @override
  List<Object?> get props => [
    id, user, name, relation, age, gender,
    phoneNumber, profession, status, verificationStatus,
    percentageAllocation, createdAt, updatedAt,
  ];
}