import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vihomeweb/data/repositories/supabase_auth_repository.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/repositories/auth_repository.dart';
import 'package:vihomeweb/presentation/controllers/auth_controller.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';

/// Provider que expone la implementación de [AuthRepository].
/// Permite ser sobreescrito (overrideWithValue) fácilmente en pruebas unitarias.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// StreamProvider que observa en tiempo real el perfil del usuario autenticado.
final currentUserProfileProvider = StreamProvider<PerfilUsuario?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchCurrentUser();
});

/// Controller reactivo del estado de autenticación de la aplicación.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
