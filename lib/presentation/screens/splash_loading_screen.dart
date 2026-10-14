import 'package:flutter/material.dart';

/// Pantalla neutral de carga que evita parpadeos o redirecciones prematuras
/// mientras se valida y rehidrata la sesión activa y el rol en Supabase.
class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF003760),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando sesión...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF535F70),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
