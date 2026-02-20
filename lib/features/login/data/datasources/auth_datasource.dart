import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../exceptions/auth_exceptions.dart';
import '../models/user_model.dart';

abstract class AuthDataSource {
  /// Inicia sesión con email y contraseña
  ///
  /// Throws [AuthException] si las credenciales son inválidas
  Future<UserEntity?> loginWithEmail({
    required String email,
    required String password,
  });

  /// Cierra la sesión actual
  Future<void> logout();

  /// Obtiene el usuario actual (si existe sesión activa)
  UserEntity? getCurrentUser();
}

class SupabaseAuthDataSource implements AuthDataSource {
  final SupabaseClient supabaseClient;

  SupabaseAuthDataSource(this.supabaseClient);

  @override
  Future<UserEntity?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Usa UserModel para mapear la respuesta
        final userModel = UserModel.fromSupabaseUser(response.user);
        return userModel.toEntity();
      }
      return null;
    } catch (e) {
      // Convierte errores de Supabase a excepciones personalizadas
      final errorMessage = e.toString();

      if (errorMessage.contains('Invalid login credentials') ||
          errorMessage.contains('User not found')) {
        throw InvalidCredentialsException();
      } else if (errorMessage.contains('unauthorized')) {
        throw UnauthorizedException();
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Network') ||
          errorMessage.contains('TimeoutException')) {
        throw NetworkException();
      }

      throw UnknownAuthException(e is Exception ? e : null, errorMessage);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw UnknownAuthException(
        e is Exception ? e : null,
        'Error durante logout: ${e.toString()}',
      );
    }
  }

  @override
  UserEntity? getCurrentUser() {
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      return UserModel.fromSupabaseUser(user).toEntity();
    }
    return null;
  }
}
