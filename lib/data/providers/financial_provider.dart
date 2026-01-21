import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/financial_repository.dart';
import '../models/deposit_model.dart';
import '../models/financial_account_model.dart';

final financialRepositoryProvider = FutureProvider<FinancialRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return FinancialRepository(apiClient);
});

final financialAccountProvider = FutureProvider<FinancialAccountModel>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.getMyAccount();
});

final depositsProvider = FutureProvider<List<DepositModel>>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.getDeposits();
});

final canDepositProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = await ref.watch(financialRepositoryProvider.future);
  return repository.canDeposit();
});