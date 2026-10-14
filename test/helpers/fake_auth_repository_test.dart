import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
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
  });
}
