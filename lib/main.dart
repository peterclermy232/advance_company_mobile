import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/providers/core_providers.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // SharedPreferences.getInstance() is async — must be awaited once here.
  // Everything downstream (secureStorageProvider → apiClientProvider →
  // all feature providers) resolves automatically as FutureProviders.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the resolved SharedPreferences instance so
        // secureStorageProvider can read it synchronously inside its builder.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AdvanceCompanyApp(),
    ),
  );
}