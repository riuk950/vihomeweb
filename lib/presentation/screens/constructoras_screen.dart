import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/data/providers.dart';

class ConstructorasView extends ConsumerWidget {
  const ConstructorasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constructorasAsync = ref.watch(constructorasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Constructoras'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showConstructoraForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Constructora'),
            ),
          ),
        ],
      ),
      body: constructorasAsync.when(
        data: (constructoras) {
          if (constructoras.isEmpty) {
            return const Center(
              child: Text('No hay constructoras registradas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: constructoras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final constructora = constructoras[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(constructora.nombre[0].toUpperCase()),
                  ),
                  title: Text(
                    constructora.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('NIT: ${constructora.nit ?? "N/A"}'),
                      Text(
                        'Ubicación: ${constructora.ciudad}, ${constructora.departamento}',
                      ),
                      Text('WhatsApp: ${constructora.whatsapp ?? "N/A"}'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Ver detalles
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showConstructoraForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ConstructoraFormDialog(),
    );
  }
}

class ConstructoraFormDialog extends ConsumerStatefulWidget {
  const ConstructoraFormDialog({super.key});

  @override
  ConsumerState<ConstructoraFormDialog> createState() =>
      _ConstructoraFormDialogState();
}

class _ConstructoraFormDialogState
    extends ConsumerState<ConstructoraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nitController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _correoController = TextEditingController();
  final _paginaWebController = TextEditingController();
  final _logoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _nitController.dispose();
    _departamentoController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _whatsappController.dispose();
    _correoController.dispose();
    _paginaWebController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final session = ref.read(sessionProvider);

      if (session == null) throw Exception('No hay sesión activa');

      await supabase.from('contructora').insert({
        'nombre': _nombreController.text.trim(),
        'nit': _nitController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'telefono_fijo': _telefonoController.text.trim(),
        'whatsap': _whatsappController.text.trim(),
        'id_user': session.user.id,
        'correo': _correoController.text.trim(),
        'sitio_web': _paginaWebController.text.trim(),
        'logo_url': _logoController.text.trim(),
      });

      ref.invalidate(constructorasProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Constructora creada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Constructora'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Constructora',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nitController,
                  decoration: const InputDecoration(
                    labelText: 'NIT',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (v) => v!.isEmpty ? 'El NIT es requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _departamentoController,
                        decoration: const InputDecoration(
                          labelText: 'Departamento',
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ciudadController,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home_work),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paginaWebController,
                  decoration: const InputDecoration(
                    labelText: 'Página Web',
                    prefixIcon: Icon(Icons.web),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _logoController,
                  decoration: const InputDecoration(
                    labelText: 'Logo',
                    prefixIcon: Icon(Icons.image),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono Fijo',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp',
                          prefixIcon: Icon(Icons.chat),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
