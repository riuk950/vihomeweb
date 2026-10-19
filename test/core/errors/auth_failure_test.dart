import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';

void main() {
  group('AuthFailure', () {
    test('subtipos deben tener mensajes en español por defecto', () {
      expect(
        const InvalidCredentialsFailure().message,
        equals('Correo o contraseña incorrectos.'),
      );
      expect(
        const UnauthorizedRoleFailure().message,
        equals('Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores.'),
      );
      expect(
        const AccountInactiveFailure().message,
        equals('Tu cuenta se encuentra inactiva. Comunícate con el soporte de Vihome.'),
      );
      expect(
        const UserAlreadyExistsFailure().message,
        equals('Este correo ya se encuentra registrado.'),
      );
      expect(
        const NetworkFailure().message,
        equals('Error de conexión con el servidor. Revisa tu internet e inténtalo de nuevo.'),
      );
      expect(
        const UnexpectedAuthFailure().message,
        equals('Ocurrió un error inesperado al procesar la solicitud.'),
      );
      expect(
        const EmailNotConfirmedFailure().message,
        equals('Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o carpeta de spam.'),
      );
      expect(
        const ConstructoraAlreadyExistsFailure().message,
        equals('Ya existe una constructora registrada con este NIT.'),
      );
    });

    test('debe permitir mensajes personalizados', () {
      const custom = InvalidCredentialsFailure('Error personalizado');
      expect(custom.message, equals('Error personalizado'));
    });
  });
}
