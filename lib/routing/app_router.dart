import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vihomeweb/data/providers.dart';
import 'package:vihomeweb/presentation/screens/dashboard_screen.dart';
import 'package:vihomeweb/presentation/screens/login_screen.dart';
import 'package:vihomeweb/presentation/screens/register_screen.dart';
import 'package:vihomeweb/presentation/screens/privacy_screen.dart';
import 'package:vihomeweb/presentation/screens/faq_screen.dart';
import 'package:vihomeweb/presentation/screens/terms_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isPublicRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/privacy' ||
          state.matchedLocation == '/faq' ||
          state.matchedLocation == '/terms';

      if (session == null) {
        return isPublicRoute ? null : '/login';
      }

      if (isPublicRoute &&
          state.matchedLocation != '/privacy' &&
          state.matchedLocation != '/faq' &&
          state.matchedLocation != '/terms') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
      GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    ],
  );
});
