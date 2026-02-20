import 'user_model.dart';

/// Model para la respuesta de login de Supabase
/// Mapea la estructura de respuesta de Supabase.auth.signInWithPassword
class LoginResponseModel {
  final UserModel user;
  final String? sessionToken;

  LoginResponseModel({required this.user, this.sessionToken});

  /// Crea un LoginResponseModel desde la respuesta de Supabase
  /// La respuesta de Supabase es: AuthResponse { user: User, session: Session }
  factory LoginResponseModel.fromSupabaseResponse(dynamic supabaseResponse) {
    final user = UserModel.fromSupabaseUser(supabaseResponse.user);
    final sessionToken = supabaseResponse.session?.accessToken as String?;

    return LoginResponseModel(user: user, sessionToken: sessionToken);
  }

  /// Convierte a JSON para almacenamiento local si es necesario
  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'sessionToken': sessionToken};
  }

  /// Crea desde JSON
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      sessionToken: json['sessionToken'] as String?,
    );
  }

  @override
  String toString() =>
      'LoginResponseModel(user: $user, sessionToken: $sessionToken)';
}
