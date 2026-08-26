import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'package:vihomeweb/presentation/screens/dashboard_screen.dart';
import 'package:vihomeweb/presentation/screens/login_screen.dart';
import 'package:vihomeweb/presentation/screens/register_screen.dart';
import 'package:vihomeweb/presentation/screens/forgot_password_screen.dart';
import 'package:vihomeweb/presentation/screens/update_password_screen.dart';
import 'package:vihomeweb/presentation/screens/privacy_screen.dart';
import 'package:vihomeweb/presentation/screens/faq_screen.dart';
import 'package:vihomeweb/presentation/screens/terms_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier();
  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final session = Supabase.instance.client.auth.currentSession;

      final isPublicRoute =
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/update-password' ||
          path == '/privacy' ||
          path == '/faq' ||
          path == '/terms';

      if (session == null) {
        return isPublicRoute ? null : '/login';
      }

      if (isPublicRoute &&
          path != '/privacy' &&
          path != '/faq' &&
          path != '/terms' &&
          path != '/forgot-password' &&
          path != '/update-password') {
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
      GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
      GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _fixUrlIfNeeded();
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  void _fixUrlIfNeeded() {
    var fixed = false;
    var url = web.window.location.href;

    final path = web.window.location.pathname;
    if (path.contains('/update-password/update-password')) {
      url = url.replaceFirst(
        '/update-password/update-password',
        '/update-password',
      );
      fixed = true;
    }

    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('code')) {
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..remove('code');
      final cleanQuery = cleanParams.isEmpty
          ? ''
          : '?${Uri(queryParameters: cleanParams).query}';
      url = '${uri.path}$cleanQuery${uri.fragment}';
      fixed = true;
    }

    if (fixed) {
      web.window.history.replaceState(null, '', url);
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
