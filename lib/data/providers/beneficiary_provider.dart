
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/beneficiary_repository.dart';
import '../models/beneficiary_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final beneficiaryRepositoryProvider =
FutureProvider<BeneficiaryRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return BeneficiaryRepository(apiClient);
});

// ── Beneficiaries list — AsyncNotifier (refreshable) ─────────────────────────

class BeneficiariesNotifier extends AsyncNotifier<List<BeneficiaryModel>> {
  @override
  Future<List<BeneficiaryModel>> build() => _fetch();

  Future<List<BeneficiaryModel>> _fetch() async {
    final repo = await ref.read(beneficiaryRepositoryProvider.future);
    return repo.getBeneficiaries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addBeneficiary(FormData formData) async {
    final repo = await ref.read(beneficiaryRepositoryProvider.future);
    await repo.createBeneficiary(formData);
    await refresh();
  }

  Future<void> updateBeneficiary(String uuid, FormData formData) async {
    final repo = await ref.read(beneficiaryRepositoryProvider.future);
    await repo.updateBeneficiary(uuid, formData);
    await refresh();
  }

  Future<void> deleteBeneficiary(String uuid) async {
    final repo = await ref.read(beneficiaryRepositoryProvider.future);
    await repo.deleteBeneficiary(uuid);
    await refresh();
  }
}

final beneficiariesProvider =
AsyncNotifierProvider<BeneficiariesNotifier, List<BeneficiaryModel>>(
  BeneficiariesNotifier.new,
);

// ── Pending beneficiaries (admin) ─────────────────────────────────────────────
// Derived from the full list — no extra API call needed.

final pendingBeneficiariesProvider =
Provider<AsyncValue<List<BeneficiaryModel>>>((ref) {
  return ref.watch(beneficiariesProvider).whenData(
        (list) => list
        .where((b) => b.verificationStatus.toLowerCase() == 'pending')
        .toList(),
  );
});

// ── Single beneficiary detail ─────────────────────────────────────────────────

final beneficiaryDetailProvider =
FutureProvider.family<BeneficiaryModel, String>((ref, uuid) async {
  final repo = await ref.read(beneficiaryRepositoryProvider.future);
  return repo.getBeneficiary(uuid);
});