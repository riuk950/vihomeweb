import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/core/theme/app_theme.dart';
import 'package:vihomeweb/routing/app_router.dart';

import 'package:vihomeweb/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    debugPrint('Warning: Supabase environment variables are not configured.');
  }

  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
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
