/// Entidad inmutable que encapsula los datos corporativos de la constructora para el onboarding.
class ConstructoraData {
  final String nit;
  final String nombre;
  final String telefono;
  final String direccion;
  final String? ciudad;
  final String? departamento;
  final String? whatsapp;
  final String? sitioWeb;
  final String? logoUrl;

  const ConstructoraData({
    required this.nit,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    this.ciudad,
    this.departamento,
    this.whatsapp,
    this.sitioWeb,
    this.logoUrl,
  });

  /// Mapea los valores sanitizados a los parámetros esperados por la función RPC
  /// PostgreSQL `public.completar_onboarding_constructora`.
  Map<String, dynamic> toRpcParams() {
    return {
      'p_nit': nit.trim(),
      'p_nombre': nombre.trim(),
      'p_telefono': telefono.trim(),
      'p_direccion': direccion.trim(),
      if (ciudad != null && ciudad!.trim().isNotEmpty) 'p_ciudad': ciudad!.trim(),
      if (departamento != null && departamento!.trim().isNotEmpty)
        'p_departamento': departamento!.trim(),
      if (whatsapp != null && whatsapp!.trim().isNotEmpty)
        'p_whatsap': whatsapp!.trim(),
      if (sitioWeb != null && sitioWeb!.trim().isNotEmpty)
        'p_sitio_web': sitioWeb!.trim(),
      if (logoUrl != null && logoUrl!.trim().isNotEmpty)
        'p_logo_url': logoUrl!.trim(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstructoraData &&
          runtimeType == other.runtimeType &&
          nit == other.nit &&
          nombre == other.nombre &&
          telefono == other.telefono &&
          direccion == other.direccion &&
          ciudad == other.ciudad &&
          departamento == other.departamento &&
          whatsapp == other.whatsapp &&
          sitioWeb == other.sitioWeb &&
          logoUrl == other.logoUrl;

  @override
  int get hashCode => Object.hash(
        nit,
        nombre,
        telefono,
        direccion,
        ciudad,
        departamento,
        whatsapp,
        sitioWeb,
        logoUrl,
      );

  @override
  String toString() =>
      'ConstructoraData(nit: $nit, nombre: $nombre, telefono: $telefono, direccion: $direccion)';
}
