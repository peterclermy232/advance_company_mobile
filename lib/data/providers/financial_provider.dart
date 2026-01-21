import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/financial_repository.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';

// Repository Provider
final financialRepositoryProvider = FutureProvider<FinancialRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return FinancialRepository(apiClient);
});

// Financial Account Provider
final financialAccountProvider = FutureProvider.autoDispose<FinancialAccountModel>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.getMyAccount();
});

// Deposits Provider
final depositsProvider = FutureProvider.autoDispose<List<DepositModel>>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.getDeposits();
});

// Can Deposit Provider
final canDepositProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.canDeposit();
});