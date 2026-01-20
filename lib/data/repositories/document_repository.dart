// ============================================
// lib/data/repositories/document_repository.dart
// ============================================
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final ApiClient _apiClient;

  DocumentRepository(this._apiClient);

  Future<List<DocumentModel>> getDocuments() async {
    final response = await _apiClient.get(ApiEndpoints.documents);
    final data = response.data['data'];
    
    if (data is List) {
      return data.map((e) => DocumentModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => DocumentModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<DocumentModel> getDocument(int id) async {
    final response = await _apiClient.get(
      ApiEndpoints.documentDetail(id),
    );
    return DocumentModel.fromJson(response.data['data']);
  }

  Future<DocumentModel> uploadDocument(FormData formData) async {
    final response = await _apiClient.uploadFile(
      ApiEndpoints.documents,
      formData,
    );
    return DocumentModel.fromJson(response.data['data']);
  }

  Future<void> deleteDocument(int id) async {
    await _apiClient.delete(ApiEndpoints.documentDetail(id));
  }

  Future<void> verifyDocument(int id) async {
    await _apiClient.post(ApiEndpoints.verifyDocument(id), data: {});
  }

  Future<void> rejectDocument(int id, String reason) async {
    await _apiClient.post(
      ApiEndpoints.rejectDocument(id),
      data: {'reason': reason},
    );
  }
}