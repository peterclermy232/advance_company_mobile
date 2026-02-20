import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/core_providers.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

final allMembersProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final response = await apiClient.get(ApiEndpoints.adminAnalytics);

  // The full response shape is:
  // { "data": { "members": [...], "summary": {...}, "monthly_trends": [...] } }
  // OR sometimes the outer wrapper is skipped.
  // We try every known path until we find a List.
  final raw = response.data;

  // Path 1: raw['data']['members']  ← most likely
  if (raw is Map && raw['data'] is Map && raw['data']['members'] is List) {
    return raw['data']['members'] as List;
  }
  // Path 2: raw['data']  is already a List
  if (raw is Map && raw['data'] is List) {
    return raw['data'] as List;
  }
  // Path 3: raw['members']  (no outer 'data' wrapper)
  if (raw is Map && raw['members'] is List) {
    return raw['members'] as List;
  }
  // Path 4: raw itself is a List
  if (raw is List) return raw;

  return [];
});

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allMembersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          Expanded(
            child: membersAsync.when(
              data: (members) {
                // ✅ FIX: API returns 'full_name' not 'first_name'/'last_name'
                final filtered = _searchQuery.isEmpty
                    ? members
                    : members.where((m) {
                  final name =
                  (m['full_name'] as String? ?? '').toLowerCase();
                  final email =
                  (m['email'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      email.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Members Found',
                    message: 'Try adjusting your search',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = filtered[index] as Map<String, dynamic>;
                    return _MemberListTile(member: member);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allMembersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  final Map<String, dynamic> member;

  const _MemberListTile({required this.member});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use 'full_name' — the API doesn't return first_name/last_name
    final fullName = member['full_name'] as String? ?? '';
    final email = member['email'] as String? ?? '';

    // ✅ FIX: API returns 'activity_status' (String "Active"/"Inactive"),
    //         not 'is_active' (bool)
    final activityStatus = member['activity_status'] as String? ?? 'Active';
    final isActive = activityStatus == 'Active';

    final role = member['role'] as String?;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ),
      title: Text(
        fullName.isNotEmpty ? fullName : email,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email, style: const TextStyle(fontSize: 12)),
          if (role != null)
            Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        child: Text(
          // ✅ Show the actual status string from the API
          activityStatus,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _showMemberDetails(context, member),
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
    final fullName = member['full_name'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _detailRow('Email', member['email']?.toString() ?? 'N/A'),
              _detailRow(
                  'Phone', member['phone_number']?.toString() ?? 'N/A'),
              _detailRow('Role', member['role']?.toString() ?? 'Member'),
              // ✅ FIX: Use activity_status not is_active
              _detailRow(
                  'Status', member['activity_status']?.toString() ?? 'Active'),
              _detailRow(
                'Total Contributions',
                member['total_contributions']?.toString() ?? '0',
              ),
              _detailRow(
                'Total Deposits',
                member['total_deposits']?.toString() ?? '0',
              ),
              _detailRow(
                'Interest Earned',
                member['interest_earned']?.toString() ?? '0',
              ),
              if (member['last_deposit_date'] != null)
                _detailRow(
                    'Last Deposit',
                    member['last_deposit_date'].toString().split('T').first),
              if (member['created_at'] != null)
                _detailRow('Joined',
                    member['created_at'].toString().split('T').first),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}