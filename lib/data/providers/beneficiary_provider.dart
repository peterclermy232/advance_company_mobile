// ============================================
// lib/data/providers/beneficiary_provider.dart
// ============================================
import '../repositories/beneficiary_repository.dart';
import '../models/beneficiary_model.dart';

final beneficiaryRepositoryProvider = Provider<BeneficiaryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BeneficiaryRepository(apiClient);
});

final beneficiariesProvider = FutureProvider<List<BeneficiaryModel>>((ref) async {
  final repository = ref.watch(beneficiaryRepositoryProvider);
  return repository.getBeneficiaries();
});