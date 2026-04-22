import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.6),
                  theme.colorScheme.tertiary.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/login'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Política de Privacidad',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              theme,
                              '1. IDENTIFICACIÓN DEL RESPONSABLE',
                              'ViHome (en adelante, "La Aplicación"), con domicilio en Boyacá, Colombia, es la responsable del tratamiento de sus datos personales.',
                            ),
                            _buildSection(
                              theme,
                              '2. DATOS RECOLECTADOS Y FINALIDAD',
                              'Recolectamos información para ofrecer un servicio inmobiliario eficiente. Los datos incluyen:',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Datos de Identificación: Nombre, email y teléfono para la gestión de cuentas.',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Ubicación (GPS): Utilizada para mostrar inmuebles cercanos y mejorar la precisión de las búsquedas. Se solicita permiso explícito en el dispositivo.',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Información de Pagos: Las suscripciones se procesan vía Google Play Billing. No almacenamos datos de tarjetas de crédito; solo recibimos el estado de la transacción proporcionado por Google.',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Publicidad: Implementamos Google AdMob para mostrar anuncios personalizados a usuarios mayores de 18 años.',
                            ),

                            _buildSection(
                              theme,
                              '3. TRANSFERENCIA DE DATOS A TERCEROS',
                              'ViHome no vende sus datos. Sin embargo, comparte información técnica con:',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Google AdMob: Para la gestión de anuncios.',
                            ),
                            _buildBulletPoint(
                              theme,
                              'Servicios de Cloud (Supabase/Firebase): Para el almacenamiento seguro de la base de datos y autenticación.',
                            ),

                            _buildSection(
                              theme,
                              '4. POLÍTICA DE MENORES',
                              'La Aplicación está restringida a usuarios de 18 años en adelante. Si detectamos el registro de un menor de edad, su cuenta y datos serán eliminados permanentemente de nuestros servidores de forma inmediata.',
                            ),

                            _buildSection(
                              theme,
                              '5. DERECHOS DEL USUARIO (ARCO)',
                              'De acuerdo con la Ley 1581 de 2012, usted puede ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición. Para eliminar su cuenta y todos los datos asociados, puede hacerlo desde la sección "Perfil > Eliminar Cuenta" dentro de la App o contactándonos al correo soporte.',
                            ),

                            _buildSection(
                              theme,
                              '6. SEGURIDAD',
                              'Implementamos protocolos de cifrado y seguridad en servidores para proteger su información contra acceso no autorizado o pérdida de datos.',
                            ),

                            const SizedBox(height: 40),
                            Center(
                              child: Text(
                                'Última actualización: Abril 2026',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
