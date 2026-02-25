import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/data/providers.dart';
import 'package:vihomeweb/domain/models/proyecto.dart';
import 'package:vihomeweb/presentation/screens/profile_screen.dart';
import 'package:vihomeweb/presentation/screens/constructoras_screen.dart';
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
              NavigationRailDestination(
                icon: Icon(Icons.foundation_outlined),
                selectedIcon: Icon(Icons.foundation),
                label: Text('Constructoras'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
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
      case 2:
        return const ConstructorasView();
      case 3:
        return const ProfileView();
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
  final _habitacionesController = TextEditingController();
  final _banosController = TextEditingController();
  final _areaController = TextEditingController();
  final _tipoPropiedadController = TextEditingController(text: 'Apartamento');
  final _videoUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _estadoController = TextEditingController(text: 'Sobre planos');
  final _pisosController = TextEditingController();
  final _estratoController = TextEditingController();
  final _financiacionController = TextEditingController();
  final _subsidioController = TextEditingController();
  DateTime? _fechaFinalizacion;
  String? _selectedConstructoraId;

  final List<String> _amenidadesDisponibles = [
    'Piscina',
    'Gimnasio',
    'Salón Social',
    'Juegos Infantiles',
    'Zona BBQ',
    'Turco',
    'Sauna',
    'Cancha Múltiple',
    'Coworking',
    'Pet Friendly',
    'Sendero Peatonal',
    'Ascensor',
    'Parqueadero',
    'Shut de basuras',
    'Portería',
    'Circuito cerrado',
    'Citofonía',
  ];
  final List<String> _amenidadesSeleccionadas = [];

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
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _precioDesdeController.dispose();
    _precioHastaController.dispose();
    _habitacionesController.dispose();
    _banosController.dispose();
    _areaController.dispose();
    _tipoPropiedadController.dispose();
    _videoUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _estadoController.dispose();
    _pisosController.dispose();
    _estratoController.dispose();
    _financiacionController.dispose();
    _subsidioController.dispose();
    super.dispose();
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
                Consumer(
                  builder: (context, ref, child) {
                    final constructorasAsync = ref.watch(constructorasProvider);
                    return constructorasAsync.when(
                      data: (constructoras) => DropdownButtonFormField<String>(
                        initialValue: _selectedConstructoraId,
                        decoration: const InputDecoration(
                          labelText: 'Constructora',
                          prefixIcon: Icon(Icons.business_center),
                        ),
                        items: constructoras
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedConstructoraId = v),
                        validator: (v) =>
                            v == null ? 'Selecciona una constructora' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) =>
                          const Text('Error al cargar constructoras'),
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                      child: DropdownButtonFormField<String>(
                        initialValue: _financiacionController.text,
                        decoration: const InputDecoration(
                          labelText: 'Aplica Financiación',
                        ),
                        items: [
                          DropdownMenuItem(value: 'Sí', child: Text('Sí')),
                          DropdownMenuItem(value: 'No', child: Text('No')),
                        ],
                        onChanged: (v) =>
                            setState(() => _financiacionController.text = v!),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _subsidioController.text,
                        decoration: const InputDecoration(
                          labelText: 'Aplica Subsidio',
                        ),
                        items: [
                          DropdownMenuItem(value: 'Sí', child: Text('Sí')),
                          DropdownMenuItem(value: 'No', child: Text('No')),
                        ],
                        onChanged: (v) =>
                            setState(() => _subsidioController.text = v!),
                        validator: (v) => v == null ? 'Requerido' : null,
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
                        controller: _pisosController,
                        decoration: const InputDecoration(labelText: 'Pisos'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _estratoController,
                        decoration: const InputDecoration(labelText: 'Estrato'),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _estadoController.text,
                  decoration: const InputDecoration(
                    labelText: 'Estado del Proyecto',
                  ),
                  items:
                      ['Sobre planos', 'En construccion', 'Entrega inmediata']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => _estadoController.text = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del Video (YouTube/Vimeo)',
                    prefixIcon: Icon(Icons.video_library),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Amenidades',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenidadesDisponibles.map((amenidad) {
                    final isSelected = _amenidadesSeleccionadas.contains(
                      amenidad,
                    );
                    return FilterChip(
                      label: Text(amenidad),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _amenidadesSeleccionadas.add(amenidad);
                          } else {
                            _amenidadesSeleccionadas.remove(amenidad);
                          }
                        });
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    );
                  }).toList(),
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
                const SizedBox(height: 24),
                Text(
                  'Detalles Temporales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    _fechaFinalizacion == null
                        ? 'Seleccionar Fecha de Finalización'
                        : 'Fecha de Finalización: ${_fechaFinalizacion!.day}/${_fechaFinalizacion!.month}/${_fechaFinalizacion!.year}',
                  ),
                  subtitle: const Text(
                    'Fecha estimada de entrega del proyecto',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _fechaFinalizacion = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
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
        'estado': _estadoController.text,
        'habitaciones': int.tryParse(_habitacionesController.text) ?? 3,
        'baños': int.tryParse(_banosController.text) ?? 2,
        'area': double.tryParse(_areaController.text) ?? 70.0,
        'fotos': imageUrls,
        'constructora_id': _selectedConstructoraId,
        'video_url': _videoUrlController.text.trim(),
        'lat': double.tryParse(_latController.text),
        'lng': double.tryParse(_lngController.text),
        'estrato': int.tryParse(_estratoController.text),
        'cantidad_pisos': int.tryParse(_pisosController.text),
        'amenidades': {'items': _amenidadesSeleccionadas},
        'financiacion': _financiacionController.text == 'Sí',
        'aplica_subsidio': _subsidioController.text == 'Sí',
        'fecha_finalizacion': _fechaFinalizacion?.toIso8601String(),
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
