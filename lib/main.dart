import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/features/login/data/repositories/auth_repository_impl.dart';
import 'package:vihomeweb/features/login/domain/usecases/login_usecase.dart';
import 'package:vihomeweb/features/login/presentation/cubit/login_cubit.dart';
import 'package:vihomeweb/features/login/presentation/pages/login_page.dart';

import 'features/login/data/datasources/auth_datasource.dart';

// Leer valores pasados en tiempo de compilación (--dart-define)
const String _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intenta cargar variables de entorno desde .env (para desarrollo)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env no está disponible, continuamos con --dart-define
  }

  // Priorizar --dart-define, luego fallback a .env
  final supabaseUrl = _supabaseUrlFromDefine.isNotEmpty
      ? _supabaseUrlFromDefine
      : dotenv.env['SUPABASE_URL'];

  final supabaseAnonKey = _supabaseAnonKeyFromDefine.isNotEmpty
      ? _supabaseAnonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'];

  // Validar que al menos una vía proporcionó las credenciales
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase configuration. Use one of:\n'
      '1. Local development: Add SUPABASE_URL and SUPABASE_ANON_KEY to .env\n'
      '2. CI/CD: Pass via --dart-define when building:\n'
      '   flutter build web --release \\\n'
      '     --dart-define=SUPABASE_URL=https://... \\\n'
      '     --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección de dependencias
    final authDataSource = SupabaseAuthDataSource(Supabase.instance.client);
    final authRepository = AuthRepositoryImpl(authDataSource);
    final loginUseCase = LoginUseCase(authRepository);

    return MaterialApp(
      title: 'Vihomeweb',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => LoginCubit(loginUseCase: loginUseCase),
        child: const LoginPage(),
      ),
    );
  }
}
