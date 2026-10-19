import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
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

    test('register debe retornar true, cerrar sesión local y permanecer en Unauthenticated para requerir confirmación', () async {
      final success = await controller().register(
        email: 'nueva@constructora.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(fakeRepo.registerCallCount, equals(1));
      expect(fakeRepo.signOutCallCount, greaterThanOrEqualTo(1));
      expect(currentState(), isA<Unauthenticated>());
    });

    test('register debe retornar false y emitir AuthErrorState ante fallo', () async {
      fakeRepo.failureToThrow = const UserAlreadyExistsFailure();

      final success = await controller().register(
        email: 'existente@constructora.com',
        password: 'password123',
      );

      expect(success, isFalse);
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

    test('login debe emitir AuthErrorState con EmailNotConfirmedFailure si el correo no está verificado', () async {
      fakeRepo.failureToThrow = const EmailNotConfirmedFailure();

      await controller().login(
        email: 'sinconfirmar@constructora.com',
        password: 'password123',
      );

      expect(currentState(), isA<AuthErrorState>());
      final errorState = currentState() as AuthErrorState;
      expect(errorState.failure, isA<EmailNotConfirmedFailure>());
      expect(
        errorState.failure.message,
        contains('Debes confirmar tu correo electrónico antes de iniciar sesión'),
      );
    });

    test('completarOnboarding debe emitir Authenticated con isCompleted == true', () async {
      fakeRepo.emitUser(
        const PerfilUsuario(
          id: 'const-1',
          email: 'empresa@constructora.com',
          rol: UserRole.constructora,
          activo: true,
          isCompleted: false,
        ),
      );

      const data = ConstructoraData(
        nit: '900123456-1',
        nombre: 'Constructora Bolívar SAS',
        telefono: '3001234567',
        direccion: 'Calle 100 # 15-20',
      );

      await controller().completarOnboarding(data);

      expect(currentState(), isA<Authenticated>());
      final auth = currentState() as Authenticated;
      expect(auth.perfil.isCompleted, isTrue);
      expect(fakeRepo.completarOnboardingCallCount, equals(1));
    });

    test('completarOnboarding debe emitir AuthErrorState con ConstructoraAlreadyExistsFailure si NIT ya existe', () async {
      fakeRepo.failureToThrow = const ConstructoraAlreadyExistsFailure();

      const data = ConstructoraData(
        nit: '900123456-1',
        nombre: 'Constructora Repetida',
        telefono: '3001234567',
        direccion: 'Calle 100 # 15-20',
      );

      await controller().completarOnboarding(data);

      expect(currentState(), isA<AuthErrorState>());
      final errorState = currentState() as AuthErrorState;
      expect(errorState.failure, isA<ConstructoraAlreadyExistsFailure>());
      expect(
        errorState.failure.message,
        contains('Ya existe una constructora registrada con este NIT'),
      );
    });

    test('reenviarConfirmacion debe invocar al repositorio con el email especificado', () async {
      await controller().reenviarConfirmacion('empresa@constructora.com');

      expect(fakeRepo.resendEmailCallCount, equals(1));
      expect(fakeRepo.lastResentEmail, equals('empresa@constructora.com'));
    });

    test('reenviarConfirmacion debe emitir AuthErrorState ante falla en el repositorio', () async {
      fakeRepo.failureToThrow = const UnexpectedAuthFailure('Error temporal del servidor');

      await controller().reenviarConfirmacion('empresa@constructora.com');

      expect(currentState(), isA<AuthErrorState>());
      final errorState = currentState() as AuthErrorState;
      expect(errorState.failure.message, equals('Error temporal del servidor'));
    });
  });
}
