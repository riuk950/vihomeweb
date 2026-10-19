import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
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
        data: const {'app': 'web', 'rol': 'CONSTRUCTORA'},
      );

      final user = res.user;
      if (user == null) {
        throw const UnexpectedAuthFailure('No se pudo crear el usuario.');
      }

      // Revocar cualquier sesión local efímera para exigir confirmación de correo antes de iniciar sesión
      await signOut();

      return PerfilUsuario(
        id: user.id,
        email: user.email ?? email,
        rol: UserRole.constructora,
        activo: true,
        isCompleted: false,
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

      var profile = await _fetchProfileById(user.id);

      // Si el usuario existe en auth.users pero no tiene perfil en usuarios_web
      // (ej. creado antes de la migración), auto-aprovisionar con rol CONSTRUCTORA
      if (profile == null) {
        try {
          final now = DateTime.now();
          await _client.from('usuarios_web').insert({
            'id': user.id,
            'email': user.email ?? email,
            'rol': 'CONSTRUCTORA',
            'activo': true,
            'is_completed': false,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          profile = await _fetchProfileById(user.id);
        } catch (_) {
          // Si falla, se manejará en la verificación estricta posterior
        }
      }

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
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') ||
          msg.contains('unconfirmed') ||
          msg.contains('email_not_confirmed') ||
          (e.code != null && e.code!.toLowerCase().contains('email_not_confirmed'))) {
        throw const EmailNotConfirmedFailure();
      }
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials')) {
        throw const InvalidCredentialsFailure();
      }
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<void> reenviarCorreoConfirmacion(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const NetworkFailure();
    }
  }

  @override
  Future<PerfilUsuario> completarOnboardingConstructora(ConstructoraData data) async {
    try {
      final res = await _client.rpc(
        'completar_onboarding_constructora',
        params: data.toRpcParams(),
      );

      if (res == null) {
        throw const UnexpectedAuthFailure('No se pudo completar el onboarding de la constructora.');
      }

      final profileMap = Map<String, dynamic>.from(res as Map);
      return PerfilUsuario.fromJson(profileMap);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == '23505' ||
          msg.contains('duplicate key') ||
          msg.contains('unique') ||
          msg.contains('contructora_nit_key')) {
        throw const ConstructoraAlreadyExistsFailure();
      }
      throw UnexpectedAuthFailure(e.message);
    } on AuthException catch (e) {
      throw UnexpectedAuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      final msg = e.toString().toLowerCase();
      if (msg.contains('23505') ||
          msg.contains('duplicate key') ||
          msg.contains('unique') ||
          msg.contains('contructora_nit_key')) {
        throw const ConstructoraAlreadyExistsFailure();
      }
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
          .from('usuarios_web')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      final profileMap = Map<String, dynamic>.from(data);
      if ((profileMap['email'] == null || (profileMap['email'] as String).isEmpty) &&
          _client.auth.currentUser?.id == userId &&
          _client.auth.currentUser?.email != null) {
        profileMap['email'] = _client.auth.currentUser!.email;
      }
      return PerfilUsuario.fromJson(profileMap);
    } catch (_) {
      return null;
    }
  }
}
