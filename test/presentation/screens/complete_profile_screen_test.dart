import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/screens/complete_profile_screen.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('CompleteProfileScreen Widget Tests', () {
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository(
        initialUser: const PerfilUsuario(
          id: 'const-test-1',
          email: 'contacto@constructora.com',
          rol: UserRole.constructora,
          activo: true,
          isCompleted: false,
        ),
      );
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CompleteProfileScreen(),
        ),
      );
    }

    void configureDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('debe renderizar todos los campos obligatorios y opcionales', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nit_field')), findsOneWidget);
      expect(find.byKey(const Key('nombre_field')), findsOneWidget);
      expect(find.byKey(const Key('telefono_field')), findsOneWidget);
      expect(find.byKey(const Key('direccion_field')), findsOneWidget);

      expect(find.byKey(const Key('ciudad_field')), findsOneWidget);
      expect(find.byKey(const Key('departamento_field')), findsOneWidget);
      expect(find.byKey(const Key('whatsapp_field')), findsOneWidget);
      expect(find.byKey(const Key('sitio_web_field')), findsOneWidget);
      expect(find.byKey(const Key('logo_url_field')), findsOneWidget);

      expect(find.byKey(const Key('completar_onboarding_btn')), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('debe validar y mostrar errores en español si los campos obligatorios están vacíos', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Presionar submit sin llenar campos
      final submitBtn = find.byKey(const Key('completar_onboarding_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('El NIT es obligatorio.'), findsOneWidget);
      expect(find.text('La razón social es obligatoria.'), findsOneWidget);
      expect(find.text('El teléfono de contacto es obligatorio.'), findsOneWidget);
      expect(find.text('La dirección corporativa es obligatoria.'), findsOneWidget);
      expect(fakeRepo.completarOnboardingCallCount, equals(0));
    });

    testWidgets('debe validar longitud mínima de NIT y formato numérico de teléfono', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nit_field')), '123'); // < 6
      await tester.enterText(find.byKey(const Key('nombre_field')), 'AB'); // < 3
      await tester.enterText(find.byKey(const Key('telefono_field')), '12345'); // < 7
      await tester.enterText(find.byKey(const Key('direccion_field')), 'Cra'); // < 5

      final submitBtn = find.byKey(const Key('completar_onboarding_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('El NIT debe tener al menos 6 caracteres.'), findsOneWidget);
      expect(find.text('La razón social debe tener al menos 3 caracteres.'), findsOneWidget);
      expect(
        find.text('El teléfono debe contener entre 7 y 15 dígitos numéricos.'),
        findsOneWidget,
      );
      expect(find.text('La dirección debe tener al menos 5 caracteres.'), findsOneWidget);
    });

    testWidgets('botón Cerrar sesión debe invocar signOut', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(fakeRepo.signOutCallCount, equals(1));
    });

    testWidgets('submit exitoso envía datos sanitizados a completarOnboardingConstructora', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nit_field')), ' 900987654-3 ');
      await tester.enterText(find.byKey(const Key('nombre_field')), ' Constructora Los Andes ');
      await tester.enterText(find.byKey(const Key('telefono_field')), ' 3109876543 ');
      await tester.enterText(find.byKey(const Key('direccion_field')), ' Av 68 # 45-20 ');
      await tester.enterText(find.byKey(const Key('ciudad_field')), ' Bogotá ');

      final submitBtn = find.byKey(const Key('completar_onboarding_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.completarOnboardingCallCount, equals(1));
      expect(
        fakeRepo.lastConstructoraData,
        equals(
          const ConstructoraData(
            nit: '900987654-3',
            nombre: 'Constructora Los Andes',
            telefono: '3109876543',
            direccion: 'Av 68 # 45-20',
            ciudad: 'Bogotá',
          ),
        ),
      );
    });

    testWidgets('debe mostrar SnackBar de error si ocurre ConstructoraAlreadyExistsFailure', (tester) async {
      configureDesktopSize(tester);

      fakeRepo.failureToThrow = const ConstructoraAlreadyExistsFailure();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nit_field')), '900987654-3');
      await tester.enterText(find.byKey(const Key('nombre_field')), 'Constructora Repetida');
      await tester.enterText(find.byKey(const Key('telefono_field')), '3109876543');
      await tester.enterText(find.byKey(const Key('direccion_field')), 'Av 68 # 45-20');

      final submitBtn = find.byKey(const Key('completar_onboarding_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ya existe una constructora registrada con este NIT'),
        findsOneWidget,
      );
    });
  });
}
