import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../repositories/beneficiary_repository.dart';
import '../models/beneficiary_model.dart';

// Repository Provider
final beneficiaryRepositoryProvider = FutureProvider<BeneficiaryRepository>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return BeneficiaryRepository(apiClient);
});

// Beneficiaries List Provider
final beneficiariesProvider = FutureProvider.autoDispose<List<BeneficiaryModel>>((ref) async {
  final repository = await ref.watch(beneficiaryRepositoryProvider.future);
  return repository.getBeneficiaries();
});