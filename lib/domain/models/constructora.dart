class Constructora {
  final String id;
  final String nombre;
  final String? nit;
  final String? departamento;
  final String? ciudad;
  final String? direccion;
  final String? telefonoFijo;
  final String? correo;
  final String? paginaWeb;
  final String? logo;
  final String? whatsapp;
  final String? idUser;
  final DateTime? createdAt;

  Constructora({
    required this.id,
    required this.nombre,
    this.nit,
    this.departamento,
    this.ciudad,
    this.direccion,
    this.telefonoFijo,
    this.correo,
    this.paginaWeb,
    this.logo,
    this.whatsapp,
    this.idUser,
    this.createdAt,
  });

  factory Constructora.fromJson(Map<String, dynamic> json) {
    return Constructora(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      nit: json['nit'],
      departamento: json['departamento'],
      ciudad: json['ciudad'],
      direccion: json['direccion'],
      telefonoFijo: json['telefono_fijo'],
      correo: json['correo'],
      paginaWeb: json['sitio_web'],
      logo: json['logo_url'],
      whatsapp: json['whatsap'],
      idUser: json['id_user'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'nit': nit,
      'departamento': departamento,
      'ciudad': ciudad,
      'direccion': direccion,
      'telefono_fijo': telefonoFijo,
      'correo': correo,
      'sitio_web': paginaWeb,
      'logo_url': logo,
      'whatsap': whatsapp,
      'id_user': idUser,
    };
  }
}
