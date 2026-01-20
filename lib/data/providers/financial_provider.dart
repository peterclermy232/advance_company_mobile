
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/financial_repository.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FinancialRepository(apiClient);
});

final financialAccountProvider = FutureProvider<FinancialAccountModel>((ref) async {
  final repository = ref.watch(financialRepositoryProvider);
  return repository.getMyAccount();
});

final depositsProvider = FutureProvider<List<DepositModel>>((ref) async {
  final repository = ref.watch(financialRepositoryProvider);
  return repository.getDeposits();
});

final canDepositProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(financialRepositoryProvider);
  return repository.canDeposit();
});