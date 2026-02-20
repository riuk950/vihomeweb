import '../../domain/entities/user_entity.dart';

/// Model para representar datos de usuario en la capa de datos
/// Contiene lógica para mapear desde JSON y desde respuestas de Supabase
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email});

  /// Crea un UserModel desde JSON (útil para deserialización)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }

  /// Crea un UserModel desde un usuario de Supabase
  /// Se usa en la datasource para mapear respuestas de auth
  factory UserModel.fromSupabaseUser(dynamic supabaseUser) {
    return UserModel(
      id: supabaseUser.id as String? ?? '',
      email: supabaseUser.email as String? ?? '',
    );
  }

  /// Convierte a UserEntity (para usar en domain layer)
  UserEntity toEntity() => UserEntity(id: id, email: email);

  /// Copia con cambios
  UserModel copyWith({String? id, String? email}) {
    return UserModel(id: id ?? this.id, email: email ?? this.email);
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email)';
}
