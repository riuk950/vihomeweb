import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/core/theme/app_theme.dart';
import 'package:vihomeweb/routing/app_router.dart';

import 'package:vihomeweb/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _UnconfiguredApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class _UnconfiguredApp extends StatelessWidget {
  const _UnconfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Aplicación mal configurada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las variables de entorno de Supabase no están definidas. '
                  'Compila con --dart-define=SUPABASE_URL y --dart-define=SUPABASE_ANON_KEY.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Vihome Web',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
