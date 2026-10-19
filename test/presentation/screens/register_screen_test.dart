import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/screens/register_screen.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  group('RegisterScreen Widget Tests', () {
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    Widget createWidgetUnderTest({String? initialPath}) {
      final router = GoRouter(
        initialLocation: initialPath ?? '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Pantalla de Login')),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('debe renderizar los campos de email, contraseña, confirmar y botón registrarse', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Únete como Constructora'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirmar Contraseña'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Registrarse'), findsOneWidget);
    });

    testWidgets('debe mostrar error si los campos están vacíos', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor completa todos los campos.'), findsOneWidget);
      expect(fakeRepo.registerCallCount, equals(0));
    });

    testWidgets('debe mostrar error si las contraseñas no coinciden', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'nueva@constructora.com');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), '123456');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar Contraseña'), '654321');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(fakeRepo.registerCallCount, equals(0));
    });

    testWidgets('registro exitoso debe mostrar diálogo de confirmación de correo y navegar a /login', (tester) async {
      fakeRepo.userToReturnOnRegister = const PerfilUsuario(
        id: 'new-constructora-id',
        email: 'contacto@constructora.com',
        rol: UserRole.constructora,
        activo: true,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'contacto@constructora.com');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'MiClaveSegura123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar Contraseña'), 'MiClaveSegura123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarse'));
      await tester.pump(); // Inicia petición
      await tester.pumpAndSettle(); // Procesa respuesta y despliega diálogo

      expect(fakeRepo.registerCallCount, equals(1));
      expect(find.text('Verifica tu correo'), findsOneWidget);
      expect(find.textContaining('Hemos enviado un enlace de confirmación a contacto@constructora.com'), findsOneWidget);
      expect(find.byKey(const Key('go_to_login_button')), findsOneWidget);

      // Al pulsar "Ir a Iniciar Sesión", debe navegar a /login
      await tester.tap(find.byKey(const Key('go_to_login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla de Login'), findsOneWidget);
    });
  });
}
