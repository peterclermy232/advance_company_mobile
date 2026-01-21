import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // 👈 Add this
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  runApp(
    const ProviderScope(
      child: AdvanceCompanyApp(),
    ),
  );
}