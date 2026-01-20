// ============================================
// lib/data/models/document_model.dart
// ============================================
import 'package:equatable/equatable.dart';
class DocumentModel extends Equatable {
  final int id;
  final int user;
  final String? userName;
  final String category;
  final String title;
  final String file;
  final String? fileUrl;
  final String status;
  final String? rejectionReason;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.user,
    this.userName,
    required this.category,
    required this.title,
    required this.file,
    this.fileUrl,
    required this.status,
    this.rejectionReason,
    required this.uploadedAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      user: json['user'] as int,
      userName: json['user_name'] as String?,
      category: json['category'] as String,
      title: json['title'] as String,
      file: json['file'] as String,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        user,
        userName,
        category,
        title,
        file,
        fileUrl,
        status,
        rejectionReason,
        uploadedAt,
        updatedAt,
      ];
}
