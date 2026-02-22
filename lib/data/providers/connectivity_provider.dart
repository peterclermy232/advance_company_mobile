import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final connectivityProvider =
StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) => results.isNotEmpty &&
        !results.contains(ConnectivityResult.none),
    loading: () => true, // assume online while checking
    error: (_, __) => true,
  );
});

// ── Offline Banner Widget ─────────────────────────────────────────────────────

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade600,
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Network-aware Scaffold helper ─────────────────────────────────────────────

class NetworkAwareScaffold extends ConsumerWidget {
  final Widget child;
  const NetworkAwareScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}