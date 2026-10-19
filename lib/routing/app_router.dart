
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/routing/web_url_cleaner.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';
import 'package:vihomeweb/presentation/screens/complete_profile_screen.dart';
import 'package:vihomeweb/presentation/screens/dashboard_screen.dart';
import 'package:vihomeweb/presentation/screens/faq_screen.dart';
import 'package:vihomeweb/presentation/screens/forgot_password_screen.dart';
import 'package:vihomeweb/presentation/screens/login_screen.dart';
import 'package:vihomeweb/presentation/screens/privacy_screen.dart';
import 'package:vihomeweb/presentation/screens/register_screen.dart';
import 'package:vihomeweb/presentation/screens/splash_loading_screen.dart';
import 'package:vihomeweb/presentation/screens/terms_screen.dart';
import 'package:vihomeweb/presentation/screens/update_password_screen.dart';

/// Lógica pura de evaluación de redirección de rutas y guards de acceso.
String? authRedirectLogic({
  required AuthState authState,
  required String path,
}) {
  final isPublicRoute =
      path == '/login' ||
      path == '/register' ||
      path == '/forgot-password' ||
      path == '/update-password' ||
      path == '/privacy' ||
      path == '/faq' ||
      path == '/terms';

  // 1. Estados iniciales de carga o validación de rol
  if (authState is AuthInitial || authState is AuthEvaluatingRole) {
    if (path == '/splash') return null;
    return isPublicRoute ? null : '/splash';
  }

  // 2. Estados no autenticados o con error
  if (authState is Unauthenticated || authState is AuthErrorState) {
    if (path == '/splash' || path == '/complete-profile') return '/login';
    return isPublicRoute ? null : '/login';
  }

  // 3. Usuario autenticado y autorizado
  if (authState is Authenticated) {
    final perfil = authState.perfil;

    // Rol ADMIN: acceso directo y exclusivo a /admin-panel
    if (perfil.rol == UserRole.admin) {
      if (path == '/admin-panel') return null;
      return '/admin-panel';
    }

    // Rol CONSTRUCTORA
    if (perfil.rol == UserRole.constructora) {
      // Caso 1: Perfil incompleto -> Onboarding obligatorio
      if (!perfil.isCompleted) {
        if (path == '/complete-profile') return null;
        return '/complete-profile';
      }

      // Caso 2: Perfil completo -> Dashboard habilitado
      if (path == '/login' ||
          path == '/register' ||
          path == '/splash' ||
          path == '/' ||
          path == '/complete-profile') {
        return '/dashboard-empresa';
      }

      if (path == '/admin-panel') {
        return '/dashboard-empresa';
      }

      return null;
    }

    return null;
  }

  return null;
}

/// Provider que expone la instancia configurada de [GoRouter].
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      return authRedirectLogic(
        authState: authState,
        path: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard-empresa',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/admin-panel',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Panel de Administración'),
            backgroundColor: const Color(0xFF003760),
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Text(
              'Panel de Administración - Vihome',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
    cleanAuthUrlParams();
  }
}
