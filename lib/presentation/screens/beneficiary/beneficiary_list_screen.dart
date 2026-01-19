// ============================================
// lib/presentation/screens/beneficiary/beneficiary_list_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/beneficiary_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/cards/beneficiary_card.dart';

class BeneficiaryListScreen extends ConsumerWidget {
  const BeneficiaryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiariesAsync = ref.watch(beneficiariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiaries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/beneficiaries/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(beneficiariesProvider);
        },
        child: beneficiariesAsync.when(
          data: (beneficiaries) {
            if (beneficiaries.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: 'No Beneficiaries Yet',
                message: 'Add beneficiaries to secure your family\'s future',
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/beneficiaries/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Beneficiary'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: beneficiaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return BeneficiaryCard(
                  beneficiary: beneficiaries[index],
                  onTap: () {
                    // Navigate to beneficiary details
                  },
                );
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(beneficiariesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/beneficiaries/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Beneficiary'),
      ),
    );
  }
}