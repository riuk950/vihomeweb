import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vihomeweb/data/providers/auth_providers.dart';
import 'package:vihomeweb/domain/models/constructora_data.dart';
import 'package:vihomeweb/presentation/controllers/auth_state.dart';

/// Pantalla de Onboarding y Registro Corporativo de Constructora (`/complete-profile`).
///
/// Permite al usuario con rol CONSTRUCTORA completar sus datos obligatorios y opcionales
/// para habilitar el acceso a la plataforma. No interactúa directamente con Supabase,
/// toda la lógica es canalizada a través de [AuthController].
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de campos obligatorios
  final _nitController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  // Controladores de campos opcionales
  final _ciudadController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _sitioWebController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nitController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _departamentoController.dispose();
    _whatsappController.dispose();
    _sitioWebController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final data = ConstructoraData(
      nit: _nitController.text.trim(),
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      ciudad: _ciudadController.text.trim().isEmpty ? null : _ciudadController.text.trim(),
      departamento:
          _departamentoController.text.trim().isEmpty ? null : _departamentoController.text.trim(),
      whatsapp:
          _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      sitioWeb:
          _sitioWebController.text.trim().isEmpty ? null : _sitioWebController.text.trim(),
      logoUrl:
          _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
    );

    await ref.read(authControllerProvider.notifier).completarOnboarding(data);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar errores de autenticación para mostrar SnackBar en español
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthErrorState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure.message),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final inProgress = _isLoading || authState is AuthLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      appBar: AppBar(
        title: const Text(
          'Registro Corporativo - Vihome',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003760),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: inProgress ? null : _logout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFC2C7D1), width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Completa el perfil de tu empresa',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003760),
                          fontFamily: 'Work Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Para comenzar a gestionar tus proyectos en Vihome, ingresa los datos oficiales de tu constructora.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF42474F),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE3E2E6)),
                      const SizedBox(height: 16),

                      // Sección: Datos Obligatorios
                      const Text(
                        'Información Obligatoria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003760),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NIT
                      TextFormField(
                        key: const Key('nit_field'),
                        controller: _nitController,
                        enabled: !inProgress,
                        decoration: const InputDecoration(
                          labelText: 'NIT o Identificación Tributaria *',
                          hintText: 'Ej. 900123456-1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El NIT es obligatorio.';
                          }
                          if (v.length < 6) {
                            return 'El NIT debe tener al menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Razón Social / Nombre
                      TextFormField(
                        key: const Key('nombre_field'),
                        controller: _nombreController,
                        enabled: !inProgress,
                        decoration: const InputDecoration(
                          labelText: 'Razón Social o Nombre Corporativo *',
                          hintText: 'Ej. Constructora Andina S.A.S.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'La razón social es obligatoria.';
                          }
                          if (v.length < 3) {
                            return 'La razón social debe tener al menos 3 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teléfono
                      TextFormField(
                        key: const Key('telefono_field'),
                        controller: _telefonoController,
                        enabled: !inProgress,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono Principal de Contacto *',
                          hintText: 'Ej. 6012345678 o 3001234567',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El teléfono de contacto es obligatorio.';
                          }
                          final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length < 7 || digitsOnly.length > 15) {
                            return 'El teléfono debe contener entre 7 y 15 dígitos numéricos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      TextFormField(
                        key: const Key('direccion_field'),
                        controller: _direccionController,
                        enabled: !inProgress,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Corporativa *',
                          hintText: 'Ej. Calle 100 # 15-20 Oficina 401',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'La dirección corporativa es obligatoria.';
                          }
                          if (v.length < 5) {
                            return 'La dirección debe tener al menos 5 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE3E2E6)),
                      const SizedBox(height: 16),

                      // Sección: Datos Opcionales
                      const Text(
                        'Información Complementaria (Opcional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003760),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('ciudad_field'),
                              controller: _ciudadController,
                              enabled: !inProgress,
                              decoration: const InputDecoration(
                                labelText: 'Ciudad',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              key: const Key('departamento_field'),
                              controller: _departamentoController,
                              enabled: !inProgress,
                              decoration: const InputDecoration(
                                labelText: 'Departamento / Estado',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        key: const Key('whatsapp_field'),
                        controller: _whatsappController,
                        enabled: !inProgress,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Comercial',
                          hintText: 'Ej. +573001234567',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.chat_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        key: const Key('sitio_web_field'),
                        controller: _sitioWebController,
                        enabled: !inProgress,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Sitio Web',
                          hintText: 'Ej. https://miempresa.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        key: const Key('logo_url_field'),
                        controller: _logoUrlController,
                        enabled: !inProgress,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL del Logotipo',
                          hintText: 'Ej. https://miempresa.com/logo.png',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botón de Enviar
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          key: const Key('completar_onboarding_btn'),
                          onPressed: inProgress ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003760),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: inProgress
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Completar Registro',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
