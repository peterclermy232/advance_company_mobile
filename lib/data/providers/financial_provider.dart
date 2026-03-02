// lib/data/providers/financial_provider.dart
//
// FIXED:
//   • Removed duplicate FinancialRepository class (was also in financial_repository.dart)
//   • depositsProvider and financialAccountProvider upgraded to AsyncNotifier for refresh()
//   • FutureProvider.autoDispose replaced → state survives tab switches, can be refreshed

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';
import '../repositories/financial_repository.dart';
import 'core_providers.dart';

// ─── Financial Repository provider ───────────────────────────────────────────

final financialRepositoryProvider =
FutureProvider<FinancialRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return FinancialRepository(apiClient);
});

// ─── Financial Account — AsyncNotifier (refreshable) ─────────────────────────

class FinancialAccountNotifier
    extends AsyncNotifier<FinancialAccountModel> {
  @override
  Future<FinancialAccountModel> build() => _fetch();

  Future<FinancialAccountModel> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.myAccount);
    final raw = response.data;
    final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
    return FinancialAccountModel.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final financialAccountProvider =
AsyncNotifierProvider<FinancialAccountNotifier, FinancialAccountModel>(
  FinancialAccountNotifier.new,
);

// ─── Deposits list — AsyncNotifier (refreshable) ──────────────────────────────

class DepositsNotifier extends AsyncNotifier<List<DepositModel>> {
  @override
  Future<List<DepositModel>> build() => _fetch();

  Future<List<DepositModel>> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.deposits);

    final raw = response.data;
    final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

    if (data is List) {
      return data.map((e) => DepositModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => DepositModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final depositsProvider =
AsyncNotifierProvider<DepositsNotifier, List<DepositModel>>(
  DepositsNotifier.new,
);

// ─── Pending deposits (admin) — AsyncNotifier ─────────────────────────────────

class PendingDepositsNotifier extends AsyncNotifier<List<DepositModel>> {
  @override
  Future<List<DepositModel>> build() => _fetch();

  Future<List<DepositModel>> _fetch() async {
    final apiClient = await ref.read(apiClientProvider.future);
    final response = await apiClient.get(ApiEndpoints.pendingApprovals);

    final raw = response.data;
    final data = (raw is Map && raw['data'] != null) ? raw['data'] : raw;

    if (data is List) {
      return data.map((e) => DepositModel.fromJson(e)).toList();
    } else if (data is Map && data.containsKey('results')) {
      return (data['results'] as List)
          .map((e) => DepositModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final pendingDepositsProvider =
AsyncNotifierProvider<PendingDepositsNotifier, List<DepositModel>>(
  PendingDepositsNotifier.new,
);