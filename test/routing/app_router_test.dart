import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/perfil_usuario.dart';
import 'package:vihomeweb/domain/models/user_role.dart';
import 'package:vihomeweb/presentation/screens/dashboard_screen.dart';
import 'package:vihomeweb/presentation/screens/login_screen.dart';
import 'package:vihomeweb/presentation/screens/splash_loading_screen.dart';
import 'package:vihomeweb/routing/app_router.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  group('Router e integración de navegación reactiva', () {
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    void configureDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('arranque sin sesión previa debe redirigir de /splash a /login automáticamente', (tester) async {
      configureDesktopSize(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      // En el frame inicial se encuentra en la pantalla neutral de carga
      expect(find.byType(SplashLoadingScreen), findsOneWidget);

      // Esperar la resolución del microtask y la redirección reactiva de GoRouter
      await tester.pumpAndSettle();

      // Debe haber redirigido a LoginScreen sin quedar atascado
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashLoadingScreen), findsNothing);
    });

    testWidgets('arranque con sesión de constructora activa debe redirigir a /dashboard-empresa', (tester) async {
      configureDesktopSize(tester);

      fakeRepo.emitUser(
        const PerfilUsuario(
          id: 'constructora-1',
          email: 'admin@constructora.com',
          rol: UserRole.constructora,
          activo: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(SplashLoadingScreen), findsNothing);
    });

    testWidgets('arranque con rol CLIENTE debe revocar sesión y redirigir a /login', (tester) async {
      configureDesktopSize(tester);

      fakeRepo.emitUser(
        const PerfilUsuario(
          id: 'cliente-1',
          email: 'cliente@gmail.com',
          rol: UserRole.cliente,
          activo: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(fakeRepo.signOutCallCount, equals(1));
    });
  });
}
