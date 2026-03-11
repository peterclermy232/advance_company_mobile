import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deposit_model.dart';
import '../repositories/financial_repository.dart';
import 'core_providers.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return FinancialRepository(apiClient: ref.watch(apiClientProvider));
});

// ── Account ────────────────────────────────────────────────────────────────

final myAccountProvider = FutureProvider<AccountModel>((ref) {
  return ref.watch(financialRepositoryProvider).getMyAccount();
});

// ── Deposits ───────────────────────────────────────────────────────────────

class DepositsState {
  final List<DepositModel> deposits;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;

  const DepositsState({
    this.deposits = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  DepositsState copyWith({
    List<DepositModel>? deposits,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
  }) {
    return DepositsState(
      deposits: deposits ?? this.deposits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class DepositsNotifier extends StateNotifier<DepositsState> {
  final FinancialRepository _repository;

  DepositsNotifier(this._repository) : super(const DepositsState()) {
    loadDeposits();
  }

  Future<void> loadDeposits({bool refresh = false}) async {
    if (refresh) {
      state = const DepositsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final deposits = await _repository.getDeposits(page: 1);
      state = DepositsState(
        deposits: deposits,
        isLoading: false,
        hasMore: deposits.length >= 20,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.page + 1;
    try {
      final more = await _repository.getDeposits(page: nextPage);
      state = state.copyWith(
        deposits: [...state.deposits, ...more],
        isLoading: false,
        hasMore: more.length >= 20,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createDeposit({
    required double amount,
    required String method,
    String? phoneNumber,
    String? mpesaTransactionId,
    String? notes,
  }) async {
    try {
      final deposit = await _repository.createDeposit(
        amount: amount,
        method: method,
        phoneNumber: phoneNumber,
        mpesaTransactionId: mpesaTransactionId,
        notes: notes,
      );
      state = state.copyWith(deposits: [deposit, ...state.deposits]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final depositsProvider =
StateNotifierProvider<DepositsNotifier, DepositsState>((ref) {
  return DepositsNotifier(ref.watch(financialRepositoryProvider));
});

// ── Monthly summary ────────────────────────────────────────────────────────

final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) {
  return ref.watch(financialRepositoryProvider).getMonthlySummary();
});