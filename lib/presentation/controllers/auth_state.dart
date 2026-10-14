import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';

/// Jerarquía inmutable de estados de autenticación y autorización.
sealed class AuthState {
  const AuthState();
}

/// Estado inicial durante el arranque o rehidratación de sesión previa.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado mientras se procesa una petición activa (ej. envío de formulario).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado crítico transitorio: Las credenciales fueron aceptadas, pero el sistema
/// está evaluando el rol en la base de datos. Bloquea navegación prematura.
final class AuthEvaluatingRole extends AuthState {
  const AuthEvaluatingRole();
}

/// Usuario autenticado con rol y permisos válidos para la web (CONSTRUCTORA o ADMIN).
final class Authenticated extends AuthState {
  final PerfilUsuario perfil;
  const Authenticated(this.perfil);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          perfil == other.perfil;

  @override
  int get hashCode => perfil.hashCode;
}

/// Sin sesión activa en el navegador.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Ocurrió un fallo en el registro, inicio de sesión o autorización.
final class AuthErrorState extends AuthState {
  final AuthFailure failure;
  const AuthErrorState(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthErrorState &&
          runtimeType == other.runtimeType &&
          failure.message == other.failure.message;

  @override
  int get hashCode => failure.message.hashCode;
}
