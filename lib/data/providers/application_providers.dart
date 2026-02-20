import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/application_model.dart';
import '../models/application_type_model.dart';
import 'core_providers.dart';

// ─── Choices: GET /applications/choices/ ─────────────────────────────────────

class ApplicationChoicesNotifier
    extends AsyncNotifier<ApplicationChoicesModel> {
  @override
  Future<ApplicationChoicesModel> build() => _fetch();

  Future<ApplicationChoicesModel> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.applicationChoices);
    // Unwrap standard { success, data: {...} } envelope
    final raw = response.data;
    final payload = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
    return ApplicationChoicesModel.fromJson(payload as Map<String, dynamic>);
  }
}

final applicationChoicesProvider =
AsyncNotifierProvider<ApplicationChoicesNotifier, ApplicationChoicesModel>(
  ApplicationChoicesNotifier.new,
);

/// Derived: just the type list — used by ApplicationFormScreen dropdown.
final applicationTypesProvider =
Provider<AsyncValue<List<ApplicationTypeModel>>>((ref) {
  return ref
      .watch(applicationChoicesProvider)
      .whenData((c) => c.applicationTypes);
});

/// Derived: just the status list — useful for filter chips / card badges.
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
    // Unwrap: { success, data: [...] }  OR  { success, data: { results: [...] } }
    final raw = response.data;
    final payload = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
    return _asList(payload)
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // ── Member actions ──────────────────────────────────────────────────────────

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

  // ── Admin actions ───────────────────────────────────────────────────────────
  // NOTE: application IDs are UUID strings, NOT integers.

  Future<void> approveApplication(String id, {String comments = ''}) async {
    final apiClient = await ref.read(apiClientProvider.future);
    await apiClient.post(
      ApiEndpoints.approveApplication(id),
      data: {'comments': comments},
    );
    await refresh();
  }

  Future<void> rejectApplication(String id, {String comments = ''}) async {
    final apiClient = await ref.read(apiClientProvider.future);
    await apiClient.post(
      ApiEndpoints.rejectApplication(id),
      data: {'comments': comments},
    );
    await refresh();
  }

  Future<void> markUnderReview(String id) async {
    final apiClient = await ref.read(apiClientProvider.future);
    await apiClient.post(ApiEndpoints.reviewApplication(id));
    await refresh();
  }
}

final applicationsProvider =
AsyncNotifierProvider<ApplicationsNotifier, List<ApplicationModel>>(
  ApplicationsNotifier.new,
);

// ─── Single application detail ────────────────────────────────────────────────
// IDs are UUID strings.

final applicationDetailProvider =
FutureProvider.family<ApplicationModel, String>((ref, id) async {
  final apiClient = await ref.read(apiClientProvider.future);
  final response = await apiClient.get(ApiEndpoints.applicationDetail(id));
  final raw = response.data;
  final payload = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
  return ApplicationModel.fromJson(payload as Map<String, dynamic>);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

List<dynamic> _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) return (data['results'] as List<dynamic>?) ?? [];
  return [];
}