// lib/data/services/application_service.dart
// Application submission and management service

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/application_model.dart';

class ApplicationService {
  final ApiClient _apiClient;

  ApplicationService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Application types supported by the backend
  static const List<String> applicationTypes = [
    'new_membership',
    'membership_withdrawal',
    'membership_transfer',
    'loan',
    'loan_top_up',
    'loan_restructure',
    'withdrawal',
    'contribution_change',
    'beneficiary_update',
    'personal_details_change',
    'next_of_kin_update',
    'statement_request',
    'other',
  ];

  // ─────────────────────────────────────────────────────────────────────────────
  // Application CRUD
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all applications (paginated)
  /// Status: pending, under_review, approved, rejected
  Future<Map<String, dynamic>> getApplications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.applications,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Create application
  /// Body (FormData): { "application_type": "...", "reason": "...", "supporting_document": <File> }
  /// Application types: new_membership, membership_withdrawal, membership_transfer, loan, loan_top_up,
  ///   loan_restructure, withdrawal, contribution_change, beneficiary_update, personal_details_change,
  ///   next_of_kin_update, statement_request, other
  Future<ApplicationModel> createApplication({
    required String applicationType,
    required String reason,
    String? supportingDocumentPath,
  }) async {
    final data = <String, dynamic>{
      'application_type': applicationType,
      'reason': reason,
    };

    if (supportingDocumentPath != null) {
      final formData = FormData.fromMap(data);
      formData.files.add(
        MapEntry(
          'supporting_document',
          await MultipartFile.fromFile(supportingDocumentPath),
        ),
      );

      final response = await _apiClient.post(
        ApiEndpoints.applications,
        data: formData,
      );
      return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.post(
        ApiEndpoints.applications,
        data: data,
      );
      return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Get application by ID
  Future<ApplicationModel> getApplicationById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.applicationDetail(id));
    return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update application (supports partial updates and file replacement)
  Future<ApplicationModel> updateApplication(
    String id, {
    String? applicationType,
    String? reason,
    String? supportingDocumentPath,
  }) async {
    final data = <String, dynamic>{};
    if (applicationType != null) data['application_type'] = applicationType;
    if (reason != null) data['reason'] = reason;

    if (supportingDocumentPath != null) {
      final formData = FormData.fromMap(data);
      formData.files.add(
        MapEntry(
          'supporting_document',
          await MultipartFile.fromFile(supportingDocumentPath),
        ),
      );

      final response = await _apiClient.patch(
        ApiEndpoints.updateApplication(id),
        data: formData,
      );
      return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.patch(
        ApiEndpoints.updateApplication(id),
        data: data,
      );
      return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Delete application
  Future<void> deleteApplication(String id) async {
    await _apiClient.delete(ApiEndpoints.deleteApplication(id));
  }

  /// Get application type choices
  /// Returns available application types
  Future<List<Map<String, dynamic>>> getApplicationChoices() async {
    final response = await _apiClient.get(ApiEndpoints.applicationChoices);
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data as List);
    }
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Admin Actions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Approve application (admin only)
  /// Body: { "admin_comments": "..." }
  Future<ApplicationModel> approveApplication(
    String id, {
    String? adminComments,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.approveApplication(id),
      data: {
        if (adminComments != null) 'admin_comments': adminComments,
      },
    );
    return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reject application (admin only)
  /// Body: { "admin_comments": "..." }
  Future<ApplicationModel> rejectApplication(
    String id, {
    required String adminComments,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectApplication(id),
      data: {'admin_comments': adminComments},
    );
    return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Move application to under review (admin only)
  /// Body: { "admin_comments": "..." }
  Future<ApplicationModel> reviewApplication(
    String id, {
    String? adminComments,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.reviewApplication(id),
      data: {
        if (adminComments != null) 'admin_comments': adminComments,
      },
    );
    return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
  }
}
