import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/core/errors/auth_failure.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/presentation/screens/login_screen.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository();
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
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('debe mostrar banner de alerta y botón de reenvío cuando el correo no está verificado',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeRepo.failureToThrow = const EmailNotConfirmedFailure();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ingresar credenciales
      final emailField = find.byType(TextField).first;
      final passField = find.byType(TextField).last;
      await tester.enterText(emailField, 'no-verificado@constructora.com');
      await tester.enterText(passField, 'password123');

      // Presionar Iniciar Sesión
      final loginBtn = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Debe aparecer el banner con el mensaje en español y el botón de reenvío
      expect(find.byKey(const Key('email_not_confirmed_banner')), findsOneWidget);
      expect(
        find.textContaining('Debes confirmar tu correo electrónico antes de iniciar sesión'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('resend_confirmation_button')), findsOneWidget);

      // Presionar el botón de reenvío
      await tester.tap(find.byKey(const Key('resend_confirmation_button')));
      await tester.pump();

      expect(fakeRepo.resendEmailCallCount, equals(1));
      expect(fakeRepo.lastResentEmail, equals('no-verificado@constructora.com'));

      // Verificar que entra en cooldown
      expect(find.textContaining('Reenviar en'), findsOneWidget);
    });
  });
}
