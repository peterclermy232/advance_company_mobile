import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/beneficiary_model.dart';

class BeneficiaryRepository {
  final ApiClient _apiClient;

  const BeneficiaryRepository(this._apiClient);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Unwrap the various shapes the backend can return:
  ///   - plain List
  ///   - { results: [...] }         (DRF pagination)
  ///   - { data: [...] }            (custom envelope)
  ///   - { data: { results: [...] } }
  List<dynamic> _toList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final inner = raw['data'] ?? raw;
      if (inner is List) return inner;
      if (inner is Map && inner['results'] is List) {
        return inner['results'] as List;
      }
      if (raw['results'] is List) return raw['results'] as List;
    }
    return [];
  }

  /// Unwrap a single-object response that may be wrapped in { data: {...} }
  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      // check for nested object like { beneficiary: {...} }
      final bene = raw['beneficiary'];
      if (bene is Map) return Map<String, dynamic>.from(bene);
      return Map<String, dynamic>.from(raw);
    }
    throw Exception('Unexpected response shape: $raw');
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<List<BeneficiaryModel>> getBeneficiaries() async {
    final response = await _apiClient.get(ApiEndpoints.beneficiaries);
    return _toList(response.data)
        .map((e) => BeneficiaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BeneficiaryModel> getBeneficiary(String uuid) async {
    final response =
    await _apiClient.get(ApiEndpoints.beneficiaryDetail(uuid));
    return BeneficiaryModel.fromJson(_toMap(response.data));
  }

  /// Create a beneficiary. Must send multipart/form-data because documents
  /// are file uploads.
  Future<BeneficiaryModel> createBeneficiary(FormData formData) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.beneficiaries,
      formData,
    );
    return BeneficiaryModel.fromJson(_toMap(response.data));
  }

  /// Update a beneficiary (PATCH with multipart if files included).
  Future<BeneficiaryModel> updateBeneficiary(
      String uuid, FormData formData) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.beneficiaryDetail(uuid),
      formData,
      options: Options(method: 'PATCH'),
    );
    return BeneficiaryModel.fromJson(_toMap(response.data));
  }

  /// Soft-delete — backend sets status = 'removed'.
  Future<void> deleteBeneficiary(String uuid) async {
    await _apiClient.delete(ApiEndpoints.beneficiaryDetail(uuid));
  }

  // ── Admin actions ──────────────────────────────────────────────────────────

  /// POST /beneficiary/{uuid}/verify/
  /// Admin only. Body: { "notes": "..." } (optional)
  Future<BeneficiaryModel> verifyBeneficiary(String uuid,
      {String notes = ''}) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyBeneficiary(uuid),
      data: {'notes': notes},
    );
    // Response: { message: "...", beneficiary: {...} }
    final raw = response.data as Map<String, dynamic>;
    final beneficiaryData =
        raw['beneficiary'] as Map<String, dynamic>? ?? raw;
    return BeneficiaryModel.fromJson(beneficiaryData);
  }

  /// POST /beneficiary/{uuid}/reject/
  /// Admin only. Body: { "reason": "..." } (required)
  Future<BeneficiaryModel> rejectBeneficiary(String uuid,
      {required String reason}) async {
    final response = await _apiClient.post(
      // Use the reject endpoint — backend defines it as detail=True action
      '/beneficiary/$uuid/reject/',
      data: {'reason': reason},
    );
    final raw = response.data as Map<String, dynamic>;
    final beneficiaryData =
        raw['beneficiary'] as Map<String, dynamic>? ?? raw;
    return BeneficiaryModel.fromJson(beneficiaryData);
  }

  /// POST /beneficiary/{uuid}/mark_deceased/
  Future<BeneficiaryModel> markDeceased(
      String uuid, {
        String? deathCertificateNumber,
        String? deathCertificatePath,
        String? deathCertificateFileName,
      }) async {
    final FormData formData;
    if (deathCertificatePath != null && deathCertificateFileName != null) {
      formData = FormData.fromMap({
        if (deathCertificateNumber != null)
          'death_certificate_number': deathCertificateNumber,
        'death_certificate': await MultipartFile.fromFile(
          deathCertificatePath,
          filename: deathCertificateFileName,
        ),
      });
      final response = await _apiClient.uploadFile(
        ApiEndpoints.markDeceased(uuid),
        formData,
      );
      final raw = response.data as Map<String, dynamic>;
      return BeneficiaryModel.fromJson(
          raw['beneficiary'] as Map<String, dynamic>? ?? raw);
    } else {
      final response = await _apiClient.post(
        ApiEndpoints.markDeceased(uuid),
        data: {
          if (deathCertificateNumber != null)
            'death_certificate_number': deathCertificateNumber,
        },
      );
      final raw = response.data as Map<String, dynamic>;
      return BeneficiaryModel.fromJson(
          raw['beneficiary'] as Map<String, dynamic>? ?? raw);
    }
  }

  /// GET /beneficiary/statistics/
  Future<Map<String, dynamic>> getStatistics() async {
    final response =
    await _apiClient.get(ApiEndpoints.beneficiaryStatistics);
    return Map<String, dynamic>.from(response.data as Map);
  }
}