// ============================================
// lib/data/models/application_model.dart
// ============================================
import 'package:equatable/equatable.dart';
class ApplicationModel extends Equatable {
  final int id;
  final int user;
  final String? userName;
  final String applicationType;
  final String reason;
  final String? supportingDocument;
  final String status;
  final String? adminComments;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final int? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApplicationModel({
    required this.id,
    required this.user,
    this.userName,
    required this.applicationType,
    required this.reason,
    this.supportingDocument,
    required this.status,
    this.adminComments,
    required this.submittedAt,
    this.reviewedAt,
    this.approvedAt,
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userName: json['user_name'] as String?,
      applicationType: json['application_type'] as String,
      reason: json['reason'] as String,
      supportingDocument: json['supporting_document'] as String?,
      status: json['status'] as String,
      adminComments: json['admin_comments'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        user,
        userName,
        applicationType,
        reason,
        supportingDocument,
        status,
        adminComments,
        submittedAt,
        reviewedAt,
        approvedAt,
        reviewedBy,
        createdAt,
        updatedAt,
      ];
}