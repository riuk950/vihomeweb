import 'dart:async';

import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/domain/repositories/auth_repository.dart';

/// Implementación en memoria de [AuthRepository] diseñada para pruebas unitarias rápidas
/// y deterministas sin dependencias de red ni mocks pesados.
class FakeAuthRepository implements AuthRepository {
  PerfilUsuario? _currentUser;
  final _controller = StreamController<PerfilUsuario?>.broadcast();

  // Simulación de respuestas y errores
  AuthFailure? failureToThrow;
  PerfilUsuario? userToReturnOnSignIn;
  PerfilUsuario? userToReturnOnRegister;

  int signInCallCount = 0;
  int registerCallCount = 0;
  int signOutCallCount = 0;
  int completarOnboardingCallCount = 0;
  int resendEmailCallCount = 0;
  String? lastResentEmail;
  ConstructoraData? lastConstructoraData;

  FakeAuthRepository({PerfilUsuario? initialUser}) : _currentUser = initialUser;

  void emitUser(PerfilUsuario? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<PerfilUsuario?> watchCurrentUser() => _controller.stream;

  @override
  Future<PerfilUsuario?> getCurrentProfile() async => _currentUser;

  @override
  Future<PerfilUsuario> registerConstructora({
    required String email,
    required String password,
  }) async {
    registerCallCount++;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    final user = userToReturnOnRegister ??
        PerfilUsuario(
          id: 'fake-reg-id',
          email: email,
          rol: UserRole.constructora,
          activo: true,
          createdAt: DateTime.now(),
        );
    emitUser(user);
    return user;
  }

  @override
  Future<PerfilUsuario> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    final user = userToReturnOnSignIn ??
        PerfilUsuario(
          id: 'fake-login-id',
          email: email,
          rol: UserRole.constructora,
          activo: true,
          createdAt: DateTime.now(),
        );

    if (!user.isAccessGranted) {
      await signOut();
      if (!user.activo) {
        throw const AccountInactiveFailure();
      }
      throw const UnauthorizedRoleFailure();
    }

    emitUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    emitUser(null);
  }

  @override
  Future<PerfilUsuario> completarOnboardingConstructora(ConstructoraData data) async {
    completarOnboardingCallCount++;
    lastConstructoraData = data;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
    final current = _currentUser ??
        PerfilUsuario(
          id: 'fake-onboarding-id',
          email: 'empresa@test.com',
          rol: UserRole.constructora,
          activo: true,
          createdAt: DateTime.now(),
        );
    final updated = current.copyWith(isCompleted: true);
    emitUser(updated);
    return updated;
  }

  @override
  Future<void> reenviarCorreoConfirmacion(String email) async {
    resendEmailCallCount++;
    lastResentEmail = email;
    if (failureToThrow != null) {
      throw failureToThrow!;
    }
  }

  void dispose() {
    _controller.close();
  }
}
