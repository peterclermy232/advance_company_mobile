import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/navigation/app_router.dart';
import 'config/theme_config.dart';

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
        // Global scaffold: applies text scaling guard + offline banner
        return MediaQuery(
          // Clamp text scale so the app doesn't break at system large-font sizes
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}