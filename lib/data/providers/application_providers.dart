import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/application_model.dart';
import '../models/application_type_model.dart';
import 'core_providers.dart';

// ─── Choices ──────────────────────────────────────────────────────────────────

class ApplicationChoicesNotifier
    extends AsyncNotifier<ApplicationChoicesModel> {
  @override
  Future<ApplicationChoicesModel> build() => _fetch();

  Future<ApplicationChoicesModel> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.applicationChoices);
    return ApplicationChoicesModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final applicationChoicesProvider =
AsyncNotifierProvider<ApplicationChoicesNotifier, ApplicationChoicesModel>(
  ApplicationChoicesNotifier.new,
);

final applicationTypesProvider =
Provider<AsyncValue<List<ApplicationTypeModel>>>((ref) {
  return ref
      .watch(applicationChoicesProvider)
      .whenData((c) => c.applicationTypes);
});

final statusChoicesProvider =
Provider<AsyncValue<List<StatusChoiceModel>>>((ref) {
  return ref
      .watch(applicationChoicesProvider)
      .whenData((c) => c.statusChoices);
});

// ─── Applications list ────────────────────────────────────────────────────────

class ApplicationsNotifier extends AsyncNotifier<List<ApplicationModel>> {
  @override
  Future<List<ApplicationModel>> build() => _fetch();

  Future<List<ApplicationModel>> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.applications);
    return _asList(response.data)
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> submitApplication({
    required String applicationType,
    required String reason,
    String? documentPath,
    String? documentName,
  }) async {
    final apiClient = await ref.read(apiClientProvider.future);

    if (documentPath != null && documentName != null) {
      final formData = FormData.fromMap({
        'application_type': applicationType,
        'reason': reason,
        'supporting_document': await MultipartFile.fromFile(
          documentPath,
          filename: documentName,
        ),
      });
      await apiClient.uploadFile(ApiEndpoints.applications, formData);
    } else {
      await apiClient.post(
        ApiEndpoints.applications,
        data: {'application_type': applicationType, 'reason': reason},
      );
    }
    await refresh();
  }

  // ── Admin actions ─────────────────────────────────────────────────────────

  /// [id] is the UUID string from ApplicationModel.id
  Future<void> approveApplication(String id, {String comments = ''}) async {
    final apiClient = await ref.read(apiClientProvider.future);
    // The endpoint helper uses int; we POST to the raw path instead
    await apiClient.post(
      '/applications/$id/approve/',
      data: {'comments': comments},
    );
    await refresh();
  }

  Future<void> rejectApplication(String id, {String comments = ''}) async {
    final apiClient = await ref.read(apiClientProvider.future);
    await apiClient.post(
      '/applications/$id/reject/',
      data: {'comments': comments},
    );
    await refresh();
  }

  Future<void> markUnderReview(String id) async {
    final apiClient = await ref.read(apiClientProvider.future);
    await apiClient.post('/applications/$id/review/');
    await refresh();
  }
}

final applicationsProvider =
AsyncNotifierProvider<ApplicationsNotifier, List<ApplicationModel>>(
  ApplicationsNotifier.new,
);

// ─── Single application detail (UUID string key) ──────────────────────────────

final applicationDetailProvider =
FutureProvider.family<ApplicationModel, String>((ref, id) async {
  final apiClient = await ref.read(apiClientProvider.future);
  final response = await apiClient.get('/applications/$id/');
  return ApplicationModel.fromJson(response.data as Map<String, dynamic>);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<dynamic> _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) return (data['results'] as List<dynamic>?) ?? [];
  return [];
}