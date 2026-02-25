class Proyecto {
  final String id;
  final String? constructoraId;
  final String? tipoPropiedad;
  final double? precioDesde;
  final double? precioHasta;
  final int? habitaciones;
  final int? banos;
  final double? area;
  final String? descripcion;
  final String? videoUrl;
  final String? ubicacionPrincipal;
  final double? lat;
  final double? lng;
  final int? estrato;
  final String? estado;
  final int? parqueaderos;
  final bool? financiacion;
  final double? cuotaInicial;
  final int? cantidadPisos;
  final bool? aplicaSubsidio;
  final DateTime? fechaFinalizacion;
  final dynamic caracteristicas;
  final Map<String, dynamic>? amenidades;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? fotos;

  Proyecto({
    required this.id,
    this.constructoraId,
    this.tipoPropiedad,
    this.precioDesde,
    this.precioHasta,
    this.habitaciones,
    this.banos,
    this.area,
    this.descripcion,
    this.videoUrl,
    this.ubicacionPrincipal,
    this.lat,
    this.lng,
    this.estrato,
    this.estado,
    this.parqueaderos,
    this.financiacion,
    this.cuotaInicial,
    this.cantidadPisos,
    this.aplicaSubsidio,
    this.fechaFinalizacion,
    this.caracteristicas,
    this.amenidades,
    this.createdAt,
    this.updatedAt,
    this.fotos,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      constructoraId: json['constructora_id'],
      tipoPropiedad: json['tipo_propiedad'],
      precioDesde: (json['precio_desde'] as num?)?.toDouble(),
      precioHasta: (json['precio_hasta'] as num?)?.toDouble(),
      habitaciones: json['habitaciones'],
      banos: json['baños'],
      area: (json['area'] as num?)?.toDouble(),
      descripcion: json['descripcion'],
      videoUrl: json['video_url'],
      ubicacionPrincipal: json['ubicacion_principal'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      estrato: json['estrato'],
      estado: json['estado'],
      parqueaderos: json['parqueaderos'],
      financiacion: json['financiacion'],
      cuotaInicial: (json['couta_inicial'] as num?)?.toDouble(),
      cantidadPisos: json['cantidad_pisos'],
      aplicaSubsidio: json['aplica_subsidio'],
      fechaFinalizacion: json['fecha_finalizacion'] != null
          ? DateTime.parse(json['fecha_finalizacion'])
          : null,
      caracteristicas: json['caracteristicas'],
      amenidades: json['amenidades'] != null
          ? Map<String, dynamic>.from(json['amenidades'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      fotos: json['fotos'] != null ? List<String>.from(json['fotos']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constructora_id': constructoraId,
      'tipo_propiedad': tipoPropiedad,
      'precio_desde': precioDesde,
      'precio_hasta': precioHasta,
      'habitaciones': habitaciones,
      'baños': banos,
      'area': area,
      'descripcion': descripcion,
      'video_url': videoUrl,
      'ubicacion_principal': ubicacionPrincipal,
      'lat': lat,
      'lng': lng,
      'estrato': estrato,
      'estado': estado,
      'parqueaderos': parqueaderos,
      'financiacion': financiacion,
      'couta_inicial': cuotaInicial,
      'cantidad_pisos': cantidadPisos,
      'aplica_subsidio': aplicaSubsidio,
      'fecha_finalizacion': fechaFinalizacion?.toIso8601String(),
      'amenidades': amenidades,
    };
  }
}
