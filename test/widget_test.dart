import 'package:flutter_test/flutter_test.dart';

import 'package:vihomeweb/core/config/env.dart';

void main() {
  group('Env', () {
    test('no debe estar configurado cuando faltan variables', () {
      expect(Env.isConfigured, isFalse);
    });

    test('debe devolver cadenas vacías por defecto', () {
      expect(Env.supabaseUrl, isEmpty);
      expect(Env.supabaseAnonKey, isEmpty);
    });
  });
}