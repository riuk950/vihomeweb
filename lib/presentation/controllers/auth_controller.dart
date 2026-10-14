import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/repositories/auth_repository.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';

/// Controlador de presentación que orquesta el ciclo de vida de autenticación.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    Future.microtask(() => checkInitialAuth());
    return const AuthInitial();
  }

  /// Rehidrata el estado de sesión al arrancar la aplicación o tras F5.
  Future<void> checkInitialAuth() async {
    try {
      final profile = await _repository.getCurrentProfile().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      // Evitar sobreescribir el estado si ya cambió durante login/registro
      if (state is! AuthInitial) return;

      if (profile != null && profile.isAccessGranted) {
        state = Authenticated(profile);
      } else {
        if (profile != null && !profile.isAccessGranted) {
          await _repository.signOut();
        }
        state = const Unauthenticated();
      }
    } catch (_) {
      if (state is AuthInitial) {
        state = const Unauthenticated();
      }
    }
  }

  /// Registro de constructora.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final profile = await _repository.registerConstructora(
        email: email,
        password: password,
      );
      state = Authenticated(profile);
    } on AuthFailure catch (f) {
      state = AuthErrorState(f);
    } catch (e) {
      state = AuthErrorState(UnexpectedAuthFailure(e.toString()));
    }
  }

  /// Inicio de sesión con evaluación preventiva de roles.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      // Estado intermedio para congelar navegación prematura mientras se valida rol en BD
      state = const AuthEvaluatingRole();
      final profile = await _repository.signIn(
        email: email,
        password: password,
      );
      state = Authenticated(profile);
    } on AuthFailure catch (f) {
      state = AuthErrorState(f);
    } catch (e) {
      state = AuthErrorState(UnexpectedAuthFailure(e.toString()));
    }
  }

  /// Cierre voluntario de sesión.
  Future<void> logout() async {
    try {
      await _repository.signOut();
    } finally {
      state = const Unauthenticated();
    }
  }

  /// Limpia estados de error en la UI.
  void clearError() {
    if (state is AuthErrorState) {
      state = const Unauthenticated();
    }
  }
}
