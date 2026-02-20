/// Excepción base para errores de autenticación de la aplicación
abstract class AppAuthException implements Exception {
  final String message;

  AppAuthException(this.message);

  @override
  String toString() => message;
}

/// Credenciales inválidas o usuario no encontrado
class InvalidCredentialsException extends AppAuthException {
  InvalidCredentialsException([String? message])
    : super(
        message ?? 'Credenciales inválidas. Verifica tu email y contraseña.',
      );
}

/// Error de conexión o timeout
class NetworkException extends AppAuthException {
  NetworkException([String? message])
    : super(message ?? 'Error de conexión. Verifica tu conexión a Internet.');
}

/// Usuario ya existe (para futuro signup)
class UserAlreadyExistsException extends AppAuthException {
  UserAlreadyExistsException([String? message])
    : super(message ?? 'Este usuario ya está registrado.');
}

/// Sesión expirada o no autorizado
class UnauthorizedException extends AppAuthException {
  UnauthorizedException([String? message])
    : super(message ?? 'Tu sesión ha expirado. Inicia sesión nuevamente.');
}

/// Error desconocido o no manejado
class UnknownAuthException extends AppAuthException {
  final Exception? originalException;

  UnknownAuthException([this.originalException, String? message])
    : super(message ?? 'Ocurrió un error desconocido. Intenta más tarde.');
}
