class Constructora {
  final String id;
  final String nombre;
  final String? nit;
  final String? departamento;
  final String? ciudad;
  final String? direccion;
  final String? telefonoFijo;
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
      'whatsap': whatsapp,
      'id_user': idUser,
    };
  }
}
