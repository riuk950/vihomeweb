import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/features/login/data/repositories/auth_repository_impl.dart';
import 'package:vihomeweb/features/login/domain/usecases/login_usecase.dart';
import 'package:vihomeweb/features/login/presentation/cubit/login_cubit.dart';
import 'package:vihomeweb/features/login/presentation/pages/login_page.dart';

// Leer valores pasados en tiempo de compilación (--dart-define)
const String _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno locales (para desarrollo)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Priorizar variables pasadas en tiempo de compilación (--dart-define),
  // si no están presentes, usar .env
  final supabaseUrl = _supabaseUrlFromDefine.isNotEmpty
      ? _supabaseUrlFromDefine
      : dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = _supabaseAnonKeyFromDefine.isNotEmpty
      ? _supabaseAnonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing Supabase configuration. Provide values via `--dart-define` '
      'or add them to a local .env file.',
    );
  }

  // Inicializar Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicialización manual de dependencias
    final authRepository = AuthRepositoryImpl(Supabase.instance.client);
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
