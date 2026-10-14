import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/controllers/auth_controller.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('AuthController', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    AuthController controller() => container.read(authControllerProvider.notifier);
    AuthState currentState() => container.read(authControllerProvider);

    test('estado inicial debe ser AuthInitial', () async {
      expect(currentState(), isA<AuthInitial>());
    });

    test('checkInitialAuth debe emitir Authenticated si existe sesión previa', () async {
      fakeRepo.emitUser(
        const PerfilUsuario(
          id: 'prev-user',
          email: 'admin@vihome.com',
          rol: UserRole.admin,
          activo: true,
        ),
      );

      await controller().checkInitialAuth();
      expect(currentState(), isA<Authenticated>());
      final auth = currentState() as Authenticated;
      expect(auth.perfil.rol, equals(UserRole.admin));
    });

    test('register debe emitir Authenticated si el registro es exitoso', () async {
      await controller().register(
        email: 'nueva@constructora.com',
        password: 'password123',
      );

      expect(currentState(), isA<Authenticated>());
      final auth = currentState() as Authenticated;
      expect(auth.perfil.rol, equals(UserRole.constructora));
    });

    test('register debe emitir AuthErrorState ante fallo', () async {
      fakeRepo.failureToThrow = const UserAlreadyExistsFailure();

      await controller().register(
        email: 'existente@constructora.com',
        password: 'password123',
      );

      expect(currentState(), isA<AuthErrorState>());
      final errorState = currentState() as AuthErrorState;
      expect(errorState.failure, isA<UserAlreadyExistsFailure>());
      expect(errorState.failure.message, equals('Este correo ya se encuentra registrado.'));
    });

    test('login debe emitir Authenticated para constructora', () async {
      fakeRepo.userToReturnOnSignIn = const PerfilUsuario(
        id: 'c1',
        email: 'empresa@constructora.com',
        rol: UserRole.constructora,
        activo: true,
      );

      await controller().login(
        email: 'empresa@constructora.com',
        password: 'password123',
      );

      expect(currentState(), isA<Authenticated>());
      final auth = currentState() as Authenticated;
      expect(auth.perfil.rol, equals(UserRole.constructora));
    });

    test('login debe emitir AuthErrorState y llamar signOut si rol es CLIENTE', () async {
      fakeRepo.userToReturnOnSignIn = const PerfilUsuario(
        id: 'cl1',
        email: 'cliente@gmail.com',
        rol: UserRole.cliente,
        activo: true,
      );

      await controller().login(
        email: 'cliente@gmail.com',
        password: 'password123',
      );

      expect(currentState(), isA<AuthErrorState>());
      final errorState = currentState() as AuthErrorState;
      expect(errorState.failure, isA<UnauthorizedRoleFailure>());
      expect(fakeRepo.signOutCallCount, equals(1));
    });

    test('logout debe emitir Unauthenticated', () async {
      await controller().login(
        email: 'empresa@constructora.com',
        password: 'password123',
      );
      expect(currentState(), isA<Authenticated>());

      await controller().logout();
      expect(currentState(), isA<Unauthenticated>());
      expect(fakeRepo.signOutCallCount, equals(1));
    });

    test('rehidratación automática en microtask debe emitir Unauthenticated si no hay sesión', () async {
      // Al instanciar el controller el microtask se programa
      controller();
      // Dejamos que los microtasks se completen
      await Future<void>.delayed(Duration.zero);
      expect(currentState(), isA<Unauthenticated>());
    });

    test('rehidratación automática en microtask con usuario CLIENTE debe cerrar sesión y emitir Unauthenticated', () async {
      fakeRepo.emitUser(
        const PerfilUsuario(
          id: 'cliente-auto',
          email: 'cliente@test.com',
          rol: UserRole.cliente,
          activo: true,
        ),
      );
      controller();
      await Future<void>.delayed(Duration.zero);
      expect(currentState(), isA<Unauthenticated>());
      expect(fakeRepo.signOutCallCount, equals(1));
    });
  });
}
