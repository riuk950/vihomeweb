/// Jerarquía de errores y fallos de autenticación tipados en español.
sealed class AuthFailure {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => '$runtimeType(message: $message)';
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Correo o contraseña incorrectos.',
  ]);
}

final class UnauthorizedRoleFailure extends AuthFailure {
  const UnauthorizedRoleFailure([
    super.message =
        'Acceso denegado: Esta plataforma es exclusiva para constructoras y administradores.',
  ]);
}

final class AccountInactiveFailure extends AuthFailure {
  const AccountInactiveFailure([
    super.message =
        'Tu cuenta se encuentra inactiva. Comunícate con el soporte de Vihome.',
  ]);
}

final class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure([
    super.message = 'Este correo ya se encuentra registrado.',
  ]);
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    super.message =
        'Error de conexión con el servidor. Revisa tu internet e inténtalo de nuevo.',
  ]);
}

final class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure([
    super.message = 'Ocurrió un error inesperado al procesar la solicitud.',
  ]);
}
