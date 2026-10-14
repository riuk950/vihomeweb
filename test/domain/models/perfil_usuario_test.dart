import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';

void main() {
  group('UserRole', () {
    test('debe parsear strings correctamente a UserRole', () {
      expect(UserRole.fromString('CONSTRUCTORA'), equals(UserRole.constructora));
      expect(UserRole.fromString('constructora'), equals(UserRole.constructora));
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('CLIENTE'), equals(UserRole.cliente));
      expect(UserRole.fromString('cliente'), equals(UserRole.cliente));
      expect(UserRole.fromString('OTRO_ROL'), equals(UserRole.desconocido));
      expect(UserRole.fromString(null), equals(UserRole.desconocido));
    });

    test('isWebAuthorized debe ser true solo para constructora y admin', () {
      expect(UserRole.constructora.isWebAuthorized, isTrue);
      expect(UserRole.admin.isWebAuthorized, isTrue);
      expect(UserRole.cliente.isWebAuthorized, isFalse);
      expect(UserRole.desconocido.isWebAuthorized, isFalse);
    });
  });

  group('PerfilUsuario', () {
    final sampleJson = {
      'id': 'usr-123',
      'email': 'test@constructora.com',
      'rol': 'CONSTRUCTORA',
      'activo': true,
      'created_at': '2026-10-07T12:00:00.000Z',
      'updated_at': '2026-10-07T12:00:00.000Z',
    };

    test('debe deserializar correctamente desde JSON', () {
      final perfil = PerfilUsuario.fromJson(sampleJson);

      expect(perfil.id, equals('usr-123'));
      expect(perfil.email, equals('test@constructora.com'));
      expect(perfil.rol, equals(UserRole.constructora));
      expect(perfil.activo, isTrue);
      expect(perfil.isAccessGranted, isTrue);
    });

    test('isAccessGranted debe ser false si el usuario está inactivo', () {
      final jsonInactivo = Map<String, dynamic>.from(sampleJson)..['activo'] = false;
      final perfil = PerfilUsuario.fromJson(jsonInactivo);

      expect(perfil.activo, isFalse);
      expect(perfil.isAccessGranted, isFalse);
    });

    test('isAccessGranted debe ser false si el rol es CLIENTE o desconocido', () {
      final jsonCliente = Map<String, dynamic>.from(sampleJson)..['rol'] = 'CLIENTE';
      final perfil = PerfilUsuario.fromJson(jsonCliente);

      expect(perfil.rol, equals(UserRole.cliente));
      expect(perfil.isAccessGranted, isFalse);
    });

    test('debe serializar a JSON correctamente', () {
      final perfil = PerfilUsuario.fromJson(sampleJson);
      final jsonOutput = perfil.toJson();

      expect(jsonOutput['id'], equals('usr-123'));
      expect(jsonOutput['email'], equals('test@constructora.com'));
      expect(jsonOutput['rol'], equals('CONSTRUCTORA'));
      expect(jsonOutput['activo'], isTrue);
    });
  });
}
