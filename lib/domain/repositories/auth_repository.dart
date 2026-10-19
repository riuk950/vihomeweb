import 'package:vihomeweb/domain/models/constructora_data.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';

/// Contrato abstracto que desacopla la autenticación y obtención de perfiles
/// de la infraestructura concreta (Supabase, Firebase o Fakes para tests).
abstract interface class AuthRepository {
  /// Emite cambios reactivos del perfil del usuario autenticado en la plataforma.
  Stream<PerfilUsuario?> watchCurrentUser();

  /// Obtiene el perfil actual en memoria o consultando el servicio.
  Future<PerfilUsuario?> getCurrentProfile();

  /// Registra una nueva constructora garantizando rol CONSTRUCTORA.
  Future<PerfilUsuario> registerConstructora({
    required String email,
    required String password,
  });

  /// Inicia sesión con credenciales y valida rol autorizado (CONSTRUCTORA o ADMIN).
  ///
  /// Si el rol es no autorizado (ej. CLIENTE) o la cuenta está inactiva,
  /// revoca la sesión y lanza un [AuthFailure].
  Future<PerfilUsuario> signIn({
    required String email,
    required String password,
  });

  /// Cierra la sesión activa en el cliente y purga el estado persistido.
  Future<void> signOut();

  /// Completa el onboarding corporativo e inserta la empresa en la base de datos.
  Future<PerfilUsuario> completarOnboardingConstructora(ConstructoraData data);

  /// Reenvía el correo de activación/confirmación de cuenta.
  Future<void> reenviarCorreoConfirmacion(String email);
}
