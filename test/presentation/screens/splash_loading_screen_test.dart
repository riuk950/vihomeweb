import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihomeweb/presentation/screens/splash_loading_screen.dart';

void main() {
  testWidgets('SplashLoadingScreen debe mostrar indicador de carga y mensaje en español', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashLoadingScreen(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando sesión...'), findsOneWidget);
  });
}
