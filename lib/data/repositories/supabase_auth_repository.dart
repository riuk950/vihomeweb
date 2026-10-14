import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/domain/repositories/auth_repository.dart';

/// Implementación del repositorio de autenticación sobre Supabase.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<PerfilUsuario?> watchCurrentUser() {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      return _fetchProfileById(user.id);
    });
  }

  @override
  Future<PerfilUsuario?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfileById(user.id);
  }

  @override
  Future<PerfilUsuario> registerConstructora({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const UnexpectedAuthFailure('No se pudo crear el usuario.');
      }

      // Reintento exponencial/controlado para esperar la ejecución del trigger en base de datos
      const maxRetries = 3;
      const retryDelay = Duration(milliseconds: 300);

      for (var i = 0; i < maxRetries; i++) {
        final profile = await _fetchProfileById(user.id);
        if (profile != null) {
          return profile;
        }
        if (i < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }

      // Fallback seguro en caso de latencia extrema del trigger
      return PerfilUsuario(
        id: user.id,
        email: user.email ?? email,
        rol: UserRole.constructora,
        activo: true,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      if (e.statusCode == '422' ||
          e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        throw const UserAlreadyExistsFailure();
      }
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<PerfilUsuario> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const InvalidCredentialsFailure();
      }

      final profile = await _fetchProfileById(user.id);

      // Verificación estricta de existencia de perfil
      if (profile == null) {
        await signOut();
        throw const UnauthorizedRoleFailure(
          'Tu cuenta no tiene un perfil configurado en la plataforma.',
        );
      }

      // Verificación estricta de autorización web (rol)
      if (!profile.rol.isWebAuthorized) {
        await signOut();
        throw const UnauthorizedRoleFailure();
      }

      // Verificación estricta de cuenta activa
      if (!profile.activo) {
        await signOut();
        throw const AccountInactiveFailure();
      }

      return profile;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid_credentials')) {
        throw const InvalidCredentialsFailure();
      }
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignorar fallos de red al cerrar sesión local
    }
  }

  Future<PerfilUsuario?> _fetchProfileById(String userId) async {
    try {
      final data = await _client
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return PerfilUsuario.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
