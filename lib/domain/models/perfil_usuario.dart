import 'package:vihomeweb/domain/models/user_role.dart';

/// Entidad inmutable que representa el perfil y estado de acceso de un usuario.
class PerfilUsuario {
  final String id;
  final String email;
  final UserRole rol;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PerfilUsuario({
    required this.id,
    required this.email,
    required this.rol,
    required this.activo,
    this.createdAt,
    this.updatedAt,
  });

  /// Determina si el usuario tiene acceso concedido a la plataforma web.
  bool get isAccessGranted => rol.isWebAuthorized && activo;

  /// Crea una instancia desde un mapa JSON proveniente de Supabase.
  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      rol: UserRole.fromString(json['rol'] as String?),
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Serializa la entidad a mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'rol': rol.toDbValue(),
      'activo': activo,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerfilUsuario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          rol == other.rol &&
          activo == other.activo;

  @override
  int get hashCode => Object.hash(id, email, rol, activo);

  @override
  String toString() =>
      'PerfilUsuario(id: $id, email: $email, rol: $rol, activo: $activo)';
}
