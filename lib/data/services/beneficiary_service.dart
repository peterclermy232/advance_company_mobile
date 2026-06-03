// lib/data/services/beneficiary_service.dart
// Beneficiary management service

import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/beneficiary_model.dart';

class BeneficiaryService {
  final ApiClient _apiClient;

  BeneficiaryService({required ApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────────────────────────────
  // Beneficiary CRUD
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all beneficiaries (paginated)
  Future<Map<String, dynamic>> getBeneficiaries({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.beneficiaries,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Create beneficiary (supports document uploads)
  /// Body supports: { "name", "relation", "age", "gender", "phone_number", "profession",
  ///   "salary_range", "percentage_allocation", "identity_document", "birth_certificate",
  ///   "additional_documents" }
  /// Use FormData for file uploads
  Future<BeneficiaryModel> createBeneficiary({
    required String name,
    required String relation, // spouse, child, parent, sibling, other
    required int age,
    required String gender, // M, F, O
    required String phoneNumber,
    required String profession,
    required String salaryRange,
    required double percentageAllocation,
    String? identityDocumentPath,
    String? birthCertificatePath,
    List<String>? additionalDocumentPaths,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'relation': relation,
      'age': age,
      'gender': gender,
      'phone_number': phoneNumber,
      'profession': profession,
      'salary_range': salaryRange,
      'percentage_allocation': percentageAllocation,
    };

    if (identityDocumentPath != null ||
        birthCertificatePath != null ||
        additionalDocumentPaths != null) {
      final formData = FormData.fromMap(data);

      if (identityDocumentPath != null) {
        formData.files.add(
          MapEntry(
            'identity_document',
            await MultipartFile.fromFile(identityDocumentPath),
          ),
        );
      }

      if (birthCertificatePath != null) {
        formData.files.add(
          MapEntry(
            'birth_certificate',
            await MultipartFile.fromFile(birthCertificatePath),
          ),
        );
      }

      if (additionalDocumentPaths != null) {
        for (var path in additionalDocumentPaths) {
          formData.files.add(
            MapEntry(
              'additional_documents',
              await MultipartFile.fromFile(path),
            ),
          );
        }
      }

      final response = await _apiClient.post(
        ApiEndpoints.beneficiaries,
        data: formData,
      );
      return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.post(
        ApiEndpoints.beneficiaries,
        data: data,
      );
      return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Get beneficiary by UUID
  Future<BeneficiaryModel> getBeneficiaryByUuid(String uuid) async {
    final response = await _apiClient.get(ApiEndpoints.beneficiaryDetail(uuid));
    return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update beneficiary (supports partial updates and file uploads)
  Future<BeneficiaryModel> updateBeneficiary(
    String uuid, {
    String? name,
    String? relation,
    int? age,
    String? gender,
    String? phoneNumber,
    String? profession,
    String? salaryRange,
    double? percentageAllocation,
    String? identityDocumentPath,
    String? birthCertificatePath,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (relation != null) data['relation'] = relation;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (profession != null) data['profession'] = profession;
    if (salaryRange != null) data['salary_range'] = salaryRange;
    if (percentageAllocation != null)
      data['percentage_allocation'] = percentageAllocation;

    if (identityDocumentPath != null || birthCertificatePath != null) {
      final formData = FormData.fromMap(data);

      if (identityDocumentPath != null) {
        formData.files.add(
          MapEntry(
            'identity_document',
            await MultipartFile.fromFile(identityDocumentPath),
          ),
        );
      }

      if (birthCertificatePath != null) {
        formData.files.add(
          MapEntry(
            'birth_certificate',
            await MultipartFile.fromFile(birthCertificatePath),
          ),
        );
      }

      final response = await _apiClient.patch(
        ApiEndpoints.updateBeneficiary(uuid),
        data: formData,
      );
      return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      final response = await _apiClient.patch(
        ApiEndpoints.updateBeneficiary(uuid),
        data: data,
      );
      return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
    }
  }

  /// Delete beneficiary
  Future<void> deleteBeneficiary(String uuid) async {
    await _apiClient.delete(ApiEndpoints.deleteBeneficiary(uuid));
  }

  /// Mark beneficiary as deceased
  /// Body: { "death_certificate": <file>, "death_certificate_number": "..." }
  Future<BeneficiaryModel> markDeceased(
    String uuid, {
    required String deathCertificatePath,
    required String deathCertificateNumber,
  }) async {
    final formData = FormData.fromMap({
      'death_certificate': await MultipartFile.fromFile(deathCertificatePath),
      'death_certificate_number': deathCertificateNumber,
    });

    final response = await _apiClient.post(
      ApiEndpoints.markDeceased(uuid),
      data: formData,
    );
    return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Admin Verification
  // ─────────────────────────────────────────────────────────────────────────────

  /// Verify beneficiary (admin only)
  Future<BeneficiaryModel> verifyBeneficiary(String uuid) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyBeneficiary(uuid),
    );
    return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Reject beneficiary (admin only)
  /// Body: { "rejection_reason": "..." }
  Future<BeneficiaryModel> rejectBeneficiary(
    String uuid, {
    required String rejectionReason,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.rejectBeneficiary(uuid),
      data: {'rejection_reason': rejectionReason},
    );
    return BeneficiaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get beneficiaries pending verification (admin only)
  Future<Map<String, dynamic>> getPendingVerification({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.pendingVerification,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get beneficiary statistics
  /// Returns: { "total": N, "verified": N, "pending": N, "rejected": N, "deceased": N }
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _apiClient.get(ApiEndpoints.beneficiaryStatistics);
    return response.data as Map<String, dynamic>;
  }
}
