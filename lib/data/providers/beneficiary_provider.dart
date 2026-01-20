
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'core_providers.dart';
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