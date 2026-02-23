import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/data/providers.dart';
import 'package:vihomeweb/domain/models/proyecto.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter/foundation.dart';

final selectedMenuIndexProvider = NotifierProvider<SelectedMenuNotifier, int>(
  SelectedMenuNotifier.new,
);

class SelectedMenuNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedMenuIndexProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              ref.read(selectedMenuIndexProvider.notifier).set(index);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'VIHOME',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Proyectos'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildBody(context, ref, selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const ProyectosView();
      default:
        return const Center(child: Text('Vista no encontrada'));
    }
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Overview')),
      body: dashboardData.when(
        data: (data) => GridView.builder(
          padding: const EdgeInsets.all(24.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 24.0,
            mainAxisSpacing: 24.0,
            childAspectRatio: 2.5,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class ProyectosView extends ConsumerWidget {
  const ProyectosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proyectos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showProyectoForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Proyecto'),
            ),
          ),
        ],
      ),
      body: proyectosAsync.when(
        data: (List<Proyecto> proyectos) {
          if (proyectos.isEmpty) {
            return const Center(child: Text('No hay proyectos registrados.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: proyectos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final proyecto = proyectos[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: proyecto.fotos != null && proyecto.fotos!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            proyecto.fotos!.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        )
                      : const Icon(Icons.business, size: 40),
                  title: Text(
                    proyecto.descripcion ?? 'Sin descripción',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Ubicación: ${proyecto.ubicacionPrincipal ?? "N/A"}',
                      ),
                      Text(
                        'Precio: \$${proyecto.precioDesde} - \$${proyecto.precioHasta}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Ver detalles del proyecto
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

  void _showProyectoForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ProyectoFormDialog(),
    );
  }
}

class ProyectoFormDialog extends ConsumerStatefulWidget {
  const ProyectoFormDialog({super.key});

  @override
  ConsumerState<ProyectoFormDialog> createState() => _ProyectoFormDialogState();
}

class _ProyectoFormDialogState extends ConsumerState<ProyectoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _precioDesdeController = TextEditingController();
  final _precioHastaController = TextEditingController();
  final _habitacionesController = TextEditingController(text: '3');
  final _banosController = TextEditingController(text: '2');
  final _areaController = TextEditingController(text: '70');
  final _tipoPropiedadController = TextEditingController(text: 'Apartamento');

  final List<Uint8List> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final images = await ImagePickerWeb.getMultiImagesAsBytes();
    if (images != null) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Proyecto'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioDesdeController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Desde',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _precioHastaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Hasta',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _habitacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Habitaciones',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _banosController,
                        decoration: const InputDecoration(labelText: 'Baños'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'Área (m²)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _tipoPropiedadController.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Propiedad',
                  ),
                  items: ['Apartamento', 'Casa', 'Lote', 'Local']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => _tipoPropiedadController.text = v!,
                ),
                const SizedBox(height: 24),
                Text(
                  'Imágenes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              entry.value,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () => setState(
                                () => _selectedImages.removeAt(entry.key),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: Colors.grey,
                        ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final List<String> imageUrls = [];

      // 1. Subir imágenes al Storage
      for (int i = 0; i < _selectedImages.length; i++) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await supabase.storage
            .from('proyectos-fotos')
            .uploadBinary(
              fileName,
              _selectedImages[i],
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        final imageUrl = supabase.storage
            .from('proyectos-fotos')
            .getPublicUrl(fileName);
        imageUrls.add(imageUrl);
      }

      // 2. Insertar proyecto en la DB
      await supabase.from('proyectos').insert({
        'descripcion': _descripcionController.text,
        'ubicacion_principal': _ubicacionController.text,
        'precio_desde':
            double.tryParse(_precioDesdeController.text) ?? 150000000,
        'precio_hasta':
            double.tryParse(_precioHastaController.text) ?? 200000000,
        'tipo_propiedad': _tipoPropiedadController.text,
        'estado': 'Sobre planos',
        'habitaciones': int.tryParse(_habitacionesController.text) ?? 3,
        'baños': int.tryParse(_banosController.text) ?? 2,
        'area': double.tryParse(_areaController.text) ?? 70.0,
        'fotos': imageUrls,
      });

      ref.invalidate(proyectosProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto creado exitosamente')),
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
}
