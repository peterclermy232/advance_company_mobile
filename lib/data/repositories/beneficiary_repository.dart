import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/beneficiary_model.dart';

class BeneficiaryRepository {
  final ApiClient _apiClient;

  BeneficiaryRepository(this._apiClient);

  Future<List<BeneficiaryModel>> getBeneficiaries() async {
    final response = await _apiClient.get(ApiEndpoints.beneficiaries);
    final data = response.data['data'];
    
    if (data is List) {
      return data.map((e) => BeneficiaryModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => BeneficiaryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<BeneficiaryModel> getBeneficiary(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.beneficiaryDetail(id),
    );
    return BeneficiaryModel.fromJson(response.data['data']);
  }

  Future<BeneficiaryModel> createBeneficiary(FormData formData) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.beneficiaries,
      formData,
    );
    return BeneficiaryModel.fromJson(response.data['data']);
  }

  Future<BeneficiaryModel> updateBeneficiary(String id, FormData formData) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.beneficiaryDetail(id),
      formData,
    );
    return BeneficiaryModel.fromJson(response.data['data']);
  }

  Future<void> deleteBeneficiary(String id) async {
    await _apiClient.delete(ApiEndpoints.beneficiaryDetail(id));
  }

  Future<void> verifyBeneficiary(String id) async {
    await _apiClient.post(ApiEndpoints.verifyBeneficiary(id), data: {});
  }
}