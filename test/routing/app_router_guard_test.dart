import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';
import 'package:vihomeweb/routing/app_router.dart';

void main() {
  group('authRedirectLogic Guards', () {
    const constructoraPerfilCompleto = PerfilUsuario(
      id: 'c-1',
      email: 'c@empresa.com',
      rol: UserRole.constructora,
      activo: true,
      isCompleted: true,
    );

    const constructoraPerfilIncompleto = PerfilUsuario(
      id: 'c-2',
      email: 'nueva@empresa.com',
      rol: UserRole.constructora,
      activo: true,
      isCompleted: false,
    );

    const adminPerfil = PerfilUsuario(
      id: 'a-1',
      email: 'admin@vihome.com',
      rol: UserRole.admin,
      activo: true,
    );

    test('usuario anónimo intentando acceder a ruta protegida debe ser redirigido a /login', () {
      final redirect = authRedirectLogic(
        authState: const Unauthenticated(),
        path: '/dashboard-empresa',
      );
      expect(redirect, equals('/login'));
    });

    test('usuario anónimo intentando acceder a /complete-profile debe ser redirigido a /login', () {
      final redirect = authRedirectLogic(
        authState: const Unauthenticated(),
        path: '/complete-profile',
      );
      expect(redirect, equals('/login'));
    });

    test('usuario anónimo intentando acceder a ruta pública debe permanecer en ella (null)', () {
      final redirect = authRedirectLogic(
        authState: const Unauthenticated(),
        path: '/login',
      );
      expect(redirect, isNull);

      final redirectRegister = authRedirectLogic(
        authState: const Unauthenticated(),
        path: '/register',
      );
      expect(redirectRegister, isNull);
    });

    test('estado AuthInitial o AuthEvaluatingRole en ruta protegida debe mostrar /splash', () {
      final redirect = authRedirectLogic(
        authState: const AuthInitial(),
        path: '/dashboard-empresa',
      );
      expect(redirect, equals('/splash'));

      final redirectEval = authRedirectLogic(
        authState: const AuthEvaluatingRole(),
        path: '/dashboard-empresa',
      );
      expect(redirectEval, equals('/splash'));
    });

    test('constructora con perfil completo en /login o /register debe ser redirigida a /dashboard-empresa', () {
      final redirectLogin = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilCompleto),
        path: '/login',
      );
      expect(redirectLogin, equals('/dashboard-empresa'));

      final redirectSplash = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilCompleto),
        path: '/splash',
      );
      expect(redirectSplash, equals('/dashboard-empresa'));
    });

    test('constructora con perfil completo en /complete-profile debe ser redirigida a /dashboard-empresa', () {
      final redirect = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilCompleto),
        path: '/complete-profile',
      );
      expect(redirect, equals('/dashboard-empresa'));
    });

    test('constructora con perfil incompleto debe ser forzada a /complete-profile desde cualquier ruta protegida', () {
      final redirectDashboard = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilIncompleto),
        path: '/dashboard-empresa',
      );
      expect(redirectDashboard, equals('/complete-profile'));

      final redirectRoot = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilIncompleto),
        path: '/',
      );
      expect(redirectRoot, equals('/complete-profile'));

      final redirectLogin = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilIncompleto),
        path: '/login',
      );
      expect(redirectLogin, equals('/complete-profile'));
    });

    test('constructora con perfil incompleto en /complete-profile debe permanecer en ella (null)', () {
      final redirect = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilIncompleto),
        path: '/complete-profile',
      );
      expect(redirect, isNull);
    });

    test('constructora intentando acceder a /admin-panel debe ser redirigida a su dashboard o complete-profile', () {
      final redirectCompleto = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilCompleto),
        path: '/admin-panel',
      );
      expect(redirectCompleto, equals('/dashboard-empresa'));

      final redirectIncompleto = authRedirectLogic(
        authState: const Authenticated(constructoraPerfilIncompleto),
        path: '/admin-panel',
      );
      expect(redirectIncompleto, equals('/complete-profile'));
    });

    test('admin autenticado en /login o / debe ser redirigido a /admin-panel', () {
      final redirectRoot = authRedirectLogic(
        authState: const Authenticated(adminPerfil),
        path: '/',
      );
      expect(redirectRoot, equals('/admin-panel'));

      final redirectLogin = authRedirectLogic(
        authState: const Authenticated(adminPerfil),
        path: '/login',
      );
      expect(redirectLogin, equals('/admin-panel'));
    });

    test('admin accediendo a /admin-panel debe tener acceso permitido (null)', () {
      final redirect = authRedirectLogic(
        authState: const Authenticated(adminPerfil),
        path: '/admin-panel',
      );
      expect(redirect, isNull);
    });

    test('admin accediendo a /complete-profile debe ser redirigido a /admin-panel', () {
      final redirect = authRedirectLogic(
        authState: const Authenticated(adminPerfil),
        path: '/complete-profile',
      );
      expect(redirect, equals('/admin-panel'));
    });

    test('estado de error debe redirigir rutas privadas a /login', () {
      final redirect = authRedirectLogic(
        authState: const AuthErrorState(UnauthorizedRoleFailure()),
        path: '/dashboard-empresa',
      );
      expect(redirect, equals('/login'));
    });
  });
}
