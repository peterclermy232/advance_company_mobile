// lib/data/services/document_service.dart
// Document management service for uploads, verification, and retrieval

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/document_model.dart';

class DocumentService {
  final ApiClient _apiClient;

  DocumentService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Document CRUD
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all documents (paginated)
  Future<Map<String, dynamic>> getDocuments({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.documents,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Create/Upload document
  /// Body (FormData): { "category": "identity|beneficiary|birth_certificate|death_certificate|additional",
  ///   "title": "...", "file": <File> }
  /// Categories:
  /// - identity: National ID, passport, etc.
  /// - beneficiary: Beneficiary documents
  /// - birth_certificate: Birth certificates
  /// - death_certificate: Death certificates
  /// - additional: Other supporting documents
  Future<DocumentModel> uploadDocument({
    required String category,
    required String title,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'category': category,
      'title': title,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.post(
      ApiEndpoints.documents,
      data: formData,
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get document by UUID
  Future<DocumentModel> getDocumentByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.documentDetail(uuid));
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update document (supports file replacement)
  /// Body (FormData): { "category": "...", "title": "...", "file": <File> }
  Future<DocumentModel> updateDocument(
    String uuid, {
    String? category,
    String? title,
    String? filePath,
  }) async {
    final data = <String, dynamic>{};
    if (category != null) data['category'] = category;
    if (title != null) data['title'] = title;

    if (filePath != null) {
      final formData = FormData.fromMap(data);
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(filePath),
        ),
      );

      final response = await _apiClient.patch(
        ApiEndpoints.updateDocument(uuid),
        data: formData,
      );
      return DocumentModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.patch(
        ApiEndpoints.updateDocument(uuid),
        data: data,
      );
      return DocumentModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Delete document
  Future<void> deleteDocument(String uuid) async {
    await _apiClient.delete(ApiEndpoints.deleteDocument(uuid));
  }

  /// Get document view URL (for accessing/downloading the file)
  /// Returns: { "file_url": "https://..." }
  Future<String> getDocumentViewUrl(String uuid) async {
    final response = await _apiClient.get(
      ApiEndpoints.getDocumentViewUrl(uuid),
    );
    return response.data['file_url'] as String;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Admin Verification
  // ─────────────────────────────────────────────────────────────────────────────

  /// Verify document (admin only)
  Future<DocumentModel> verifyDocument(String uuid) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyDocument(uuid),
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reject document (admin only)
  /// Body: { "rejection_reason": "..." }
  Future<DocumentModel> rejectDocument(
    String uuid, {
    required String rejectionReason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectDocument(uuid),
      data: {'rejection_reason': rejectionReason},
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
