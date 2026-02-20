import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/features/login/data/models/user_model.dart';
import 'package:vihomeweb/features/login/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    const testId = 'user123';
    const testEmail = 'test@example.com';

    group('fromJson', () {
      test('debe crear UserModel desde JSON válido', () {
        final json = {'id': testId, 'email': testEmail};

        final result = UserModel.fromJson(json);

        expect(result.id, testId);
        expect(result.email, testEmail);
      });

      test('debe manejar valores nulos en JSON', () {
        final json = <String, dynamic>{'id': null, 'email': null};

        final result = UserModel.fromJson(json);

        expect(result.id, '');
        expect(result.email, '');
      });

      test('debe manejar JSON vacío', () {
        final result = UserModel.fromJson({});

        expect(result.id, '');
        expect(result.email, '');
      });
    });

    group('toJson', () {
      test('debe convertir UserModel a JSON', () {
        final userModel = UserModel(id: testId, email: testEmail);

        final result = userModel.toJson();

        expect(result, {'id': testId, 'email': testEmail});
      });
    });

    group('fromSupabaseUser', () {
      test('debe crear UserModel desde usuario de Supabase', () {
        final mockSupabaseUser = _MockSupabaseUser(
          id: testId,
          email: testEmail,
        );

        final result = UserModel.fromSupabaseUser(mockSupabaseUser);

        expect(result.id, testId);
        expect(result.email, testEmail);
      });

      test('debe manejar usuario de Supabase sin email', () {
        final mockSupabaseUser = _MockSupabaseUser(id: testId, email: null);

        final result = UserModel.fromSupabaseUser(mockSupabaseUser);

        expect(result.id, testId);
        expect(result.email, '');
      });
    });

    group('toEntity', () {
      test('debe convertir UserModel a UserEntity', () {
        final userModel = UserModel(id: testId, email: testEmail);

        final result = userModel.toEntity();

        expect(result, isA<UserEntity>());
        expect(result.id, testId);
        expect(result.email, testEmail);
      });
    });

    group('copyWith', () {
      test('debe copiar UserModel sin cambios', () {
        final userModel = UserModel(id: testId, email: testEmail);

        final result = userModel.copyWith();

        expect(result.id, testId);
        expect(result.email, testEmail);
      });

      test('debe copiar UserModel con cambios en id', () {
        final userModel = UserModel(id: testId, email: testEmail);
        const newId = 'newId';

        final result = userModel.copyWith(id: newId);

        expect(result.id, newId);
        expect(result.email, testEmail);
      });

      test('debe copiar UserModel con cambios en email', () {
        final userModel = UserModel(id: testId, email: testEmail);
        const newEmail = 'new@example.com';

        final result = userModel.copyWith(email: newEmail);

        expect(result.id, testId);
        expect(result.email, newEmail);
      });
    });

    group('equatable', () {
      test('dos UserModels con mismos valores deben ser iguales', () {
        final user1 = UserModel(id: testId, email: testEmail);
        final user2 = UserModel(id: testId, email: testEmail);

        expect(user1, equals(user2));
      });

      test('dos UserModels con diferentes valores no deben ser iguales', () {
        final user1 = UserModel(id: testId, email: testEmail);
        final user2 = UserModel(id: 'other', email: testEmail);

        expect(user1, isNot(equals(user2)));
      });
    });
  });
}

/// Mock de usuario de Supabase para testing
class _MockSupabaseUser {
  final String id;
  final String? email;

  _MockSupabaseUser({required this.id, this.email});
}
