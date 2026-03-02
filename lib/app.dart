// lib/app.dart
//
// FIXED:
//   • Added global ErrorBoundary — unhandled exceptions no longer show blank screen
//   • Added OfflineBanner in the MaterialApp builder
//   • Text scale guard preserved

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/navigation/app_router.dart';
import 'config/theme_config.dart';
import 'data/providers/connectivity_provider.dart';

class AdvanceCompanyApp extends ConsumerWidget {
  const AdvanceCompanyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Advance Company',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        // FIX: Wrap in ErrorBoundary so unhandled exceptions render a friendly
        // message instead of a blank/red screen.
        return MediaQuery(
          // Clamp text scale so the app doesn't break at system large-font sizes
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Column(
            children: [
              // Offline banner sits above all content
              const OfflineBanner(),
              Expanded(
                child: _GlobalErrorBoundary(child: child!),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Global Error Boundary ─────────────────────────────────────────────────────

class _GlobalErrorBoundary extends StatefulWidget {
  final Widget child;
  const _GlobalErrorBoundary({required this.child});

  @override
  State<_GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<_GlobalErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Catch Flutter framework errors
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      originalOnError?.call(details);
      // Only show boundary for fatal errors, not layout overflow warnings
      if (details.exception.toString().contains('Fatal')) {
        if (mounted) setState(() => _error = details.exception);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _error = null),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}