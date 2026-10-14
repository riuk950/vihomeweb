import 'package:web/web.dart' as web;

void launchDeepLink(String url) {
  try {
    final link = web.HTMLAnchorElement()
      ..href = url
      ..style.display = 'none';
    web.document.body?.append(link);
    link.click();
    link.remove();
  } catch (_) {
    // Manejo de excepciones en navegador
  }
}
