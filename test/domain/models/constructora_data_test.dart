import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';

void main() {
  group('ConstructoraData', () {
    test('toRpcParams debe sanitizar espacios y mapear campos requeridos', () {
      const data = ConstructoraData(
        nit: '  900123456-1  ',
        nombre: '  Constructora Los Andes SAS  ',
        telefono: '  6015551234  ',
        direccion: '  Calle 100 # 15-20  ',
      );

      final params = data.toRpcParams();

      expect(params['p_nit'], equals('900123456-1'));
      expect(params['p_nombre'], equals('Constructora Los Andes SAS'));
      expect(params['p_telefono'], equals('6015551234'));
      expect(params['p_direccion'], equals('Calle 100 # 15-20'));
      expect(params.containsKey('p_ciudad'), isFalse);
      expect(params.containsKey('p_departamento'), isFalse);
      expect(params.containsKey('p_whatsap'), isFalse);
      expect(params.containsKey('p_sitio_web'), isFalse);
      expect(params.containsKey('p_logo_url'), isFalse);
    });

    test('toRpcParams debe incluir campos opcionales cuando tengan contenido', () {
      const data = ConstructoraData(
        nit: '900123456-1',
        nombre: 'Constructora Los Andes',
        telefono: '3001234567',
        direccion: 'Carrera 7 # 72-10',
        ciudad: ' Bogotá ',
        departamento: ' Cundinamarca ',
        whatsapp: ' 3001234567 ',
        sitioWeb: ' https://losandes.com ',
        logoUrl: ' https://losandes.com/logo.png ',
      );

      final params = data.toRpcParams();

      expect(params['p_ciudad'], equals('Bogotá'));
      expect(params['p_departamento'], equals('Cundinamarca'));
      expect(params['p_whatsap'], equals('3001234567'));
      expect(params['p_sitio_web'], equals('https://losandes.com'));
      expect(params['p_logo_url'], equals('https://losandes.com/logo.png'));
    });
  });
}
