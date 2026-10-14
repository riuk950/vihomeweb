/// Roles de usuario soportados en el sistema Vihome.
enum UserRole {
  constructora,
  admin,
  cliente,
  desconocido;

  /// Determina si el rol tiene permiso para interactuar con la plataforma web.
  bool get isWebAuthorized => this == constructora || this == admin;

  /// Parsea un String proveniente de Supabase a [UserRole].
  static UserRole fromString(String? value) {
    if (value == null) return UserRole.desconocido;
    switch (value.trim().toUpperCase()) {
      case 'CONSTRUCTORA':
        return UserRole.constructora;
      case 'ADMIN':
        return UserRole.admin;
      case 'CLIENTE':
        return UserRole.cliente;
      default:
        return UserRole.desconocido;
    }
  }

  /// Retorna la representación en mayúsculas esperada en base de datos.
  String toDbValue() {
    switch (this) {
      case UserRole.constructora:
        return 'CONSTRUCTORA';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.cliente:
        return 'CLIENTE';
      case UserRole.desconocido:
        return 'DESCONOCIDO';
    }
  }
}
