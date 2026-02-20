import 'package:equatable/equatable.dart';

class ApplicationActivityModel extends Equatable {
  final String id;
  final String action;
  final String? notes;
  final DateTime createdAt;
  final String? userName;

  const ApplicationActivityModel({
    required this.id,
    required this.action,
    this.notes,
    required this.createdAt,
    this.userName,
  });

  factory ApplicationActivityModel.fromJson(Map<String, dynamic> json) {
    return ApplicationActivityModel(
      id: json['id'] as String,
      action: json['action'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, action, notes, createdAt, userName];
}

class ApplicationModel extends Equatable {
  final String id;         // UUID string, e.g. "254c53f4-6bb0-..."
  final String user;       // UUID string
  final String? userName;
  final String applicationType;
  final String reason;
  final String? supportingDocument;
  final String status;
  final String? adminComments;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final String? reviewedBy; // UUID string or null
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ApplicationActivityModel> activities;

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
    this.activities = const [],
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      user: json['user'] as String,
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
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map((e) => ApplicationActivityModel.fromJson(
          e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Status helpers ────────────────────────────────────────────────────────
  bool get isPending => status == 'pending';
  bool get isUnderReview => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// Human-readable label for the application type
  String get applicationTypeLabel =>
      applicationType.replaceAll('_', ' ').toUpperCase();

  /// Most recent activity action, e.g. "submitted", "approved"
  String? get latestActivity =>
      activities.isNotEmpty ? activities.first.action : null;

  @override
  List<Object?> get props => [
    id, user, userName, applicationType, reason, supportingDocument,
    status, adminComments, submittedAt, reviewedAt, approvedAt,
    reviewedBy, createdAt, updatedAt, activities,
  ];
}