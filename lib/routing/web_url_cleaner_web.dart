import 'package:web/web.dart' as web;

/// Implementación web para sanitizar parámetros de sesión y OTP en la URL.
void cleanAuthUrlParams() {
  try {
    var url = web.window.location.href;
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('code')) {
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..remove('code');
      final cleanQuery = cleanParams.isEmpty
          ? ''
          : '?${Uri(queryParameters: cleanParams).query}';
      url = '${uri.path}$cleanQuery${uri.fragment}';
      web.window.history.replaceState(null, '', url);
    }
  } catch (_) {
    // Manejo silencioso ante restricciones del navegador
  }
}
