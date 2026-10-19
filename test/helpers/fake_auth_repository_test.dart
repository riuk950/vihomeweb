import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'fake_auth_repository.dart';

void main() {
  group('FakeAuthRepository', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('debe permitir registro de constructora exitoso', () async {
      final user = await repository.registerConstructora(
        email: 'test@constructora.com',
        password: 'password123',
      );

      expect(user.rol, equals(UserRole.constructora));
      expect(user.email, equals('test@constructora.com'));
      expect(repository.registerCallCount, equals(1));
    });

    test('debe permitir login exitoso con constructora', () async {
      final user = await repository.signIn(
        email: 'test@constructora.com',
        password: 'password123',
      );

      expect(user.rol, equals(UserRole.constructora));
      expect(repository.signInCallCount, equals(1));
    });

    test('debe revocar sesión y lanzar UnauthorizedRoleFailure si rol es CLIENTE', () async {
      repository.userToReturnOnSignIn = PerfilUsuario(
        id: 'usr-client',
        email: 'cliente@gmail.com',
        rol: UserRole.cliente,
        activo: true,
      );

      expect(
        () => repository.signIn(
          email: 'cliente@gmail.com',
          password: 'password123',
        ),
        throwsA(isA<UnauthorizedRoleFailure>()),
      );
      expect(repository.signOutCallCount, equals(1));
    });

    test('debe revocar sesión y lanzar AccountInactiveFailure si usuario está inactivo', () async {
      repository.userToReturnOnSignIn = PerfilUsuario(
        id: 'usr-inactive',
        email: 'inactivo@constructora.com',
        rol: UserRole.constructora,
        activo: false,
      );

      expect(
        () => repository.signIn(
          email: 'inactivo@constructora.com',
          password: 'password123',
        ),
        throwsA(isA<AccountInactiveFailure>()),
      );
      expect(repository.signOutCallCount, equals(1));
    });

    test('signOut debe limpiar el usuario activo', () async {
      await repository.signIn(
        email: 'test@constructora.com',
        password: 'password123',
      );
      expect(await repository.getCurrentProfile(), isNotNull);

      await repository.signOut();
      expect(await repository.getCurrentProfile(), isNull);
      expect(repository.signOutCallCount, equals(1));
    });

    test('completarOnboardingConstructora actualiza isCompleted a true en el usuario actual', () async {
      final initialUser = PerfilUsuario(
        id: 'usr-1',
        email: 'test@empresa.com',
        rol: UserRole.constructora,
        activo: true,
        isCompleted: false,
      );
      repository.emitUser(initialUser);

      final data = const ConstructoraData(
        nit: '900123456-1',
        nombre: 'Constructora Bolívar SAS',
        telefono: '6012345678',
        direccion: 'Calle 100 # 15-20',
      );

      final result = await repository.completarOnboardingConstructora(data);

      expect(result.isCompleted, isTrue);
      final updated = await repository.getCurrentProfile();
      expect(updated, isNotNull);
      expect(updated!.isCompleted, isTrue);
      expect(repository.completarOnboardingCallCount, equals(1));
      expect(repository.lastConstructoraData, equals(data));
    });

    test('completarOnboardingConstructora lanza error configurado si failureToThrow existe', () async {
      repository.failureToThrow = const ConstructoraAlreadyExistsFailure();

      final data = const ConstructoraData(
        nit: '900123456-1',
        nombre: 'Constructora Repetida',
        telefono: '6012345678',
        direccion: 'Calle 100 # 15-20',
      );

      expect(
        () => repository.completarOnboardingConstructora(data),
        throwsA(isA<ConstructoraAlreadyExistsFailure>()),
      );
    });

    test('reenviarCorreoConfirmacion incrementa contador y guarda último correo', () async {
      await repository.reenviarCorreoConfirmacion('pending@empresa.com');

      expect(repository.resendEmailCallCount, equals(1));
      expect(repository.lastResentEmail, equals('pending@empresa.com'));
    });
  });
}
