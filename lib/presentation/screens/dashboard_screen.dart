import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/core/theme/app_theme.dart';
import 'package:vihomeweb/data/providers.dart';
import 'package:vihomeweb/domain/dashboard_item.dart';
import 'package:vihomeweb/domain/models/proyecto.dart';
import 'package:vihomeweb/presentation/screens/profile_screen.dart';
import 'package:vihomeweb/presentation/screens/constructoras_screen.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:vihomeweb/core/responsive.dart';

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
    return Theme(
      data: AppTheme.azureLight,
      child: Builder(
        builder: (context) {
          final selectedIndex = ref.watch(selectedMenuIndexProvider);
          return _buildLayout(context, ref, selectedIndex);
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, WidgetRef ref, int selectedIndex) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'VIHOME',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _buildBody(context, ref, selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            ref.read(selectedMenuIndexProvider.notifier).set(index);
          },
          indicatorColor: azureSecondaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationRequest(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationRequest(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business),
              label: 'Proyectos',
            ),
            NavigationRequest(
              icon: Icon(Icons.foundation_outlined),
              selectedIcon: Icon(Icons.foundation),
              label: 'Constructoras',
            ),
            NavigationRequest(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _DashboardSidebar(
            selectedIndex: selectedIndex,
            onSelected: (index) {
              ref.read(selectedMenuIndexProvider.notifier).set(index);
            },
            onNewProject: () => _openNewProject(context, ref),
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildBody(context, ref, selectedIndex)),
        ],
      ),
    );
  }

  void _openNewProject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ProyectoFormDialog(),
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

class _DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onNewProject;
  final VoidCallback onLogout;

  const _DashboardSidebar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onNewProject,
    required this.onLogout,
  });

  static const _items = [
    (
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    (
      icon: Icons.architecture_outlined,
      selectedIcon: Icons.architecture,
      label: 'Proyectos',
    ),
    (
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'Constructoras',
    ),
    (
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(right: BorderSide(color: azureOutlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/vihome.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIHOME',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: azurePrimary,
                        ),
                      ),
                      Text(
                        'Enterprise Portal',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: azureOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _items.length; i++)
              _SidebarItem(
                icon: _items[i].icon,
                selectedIcon: _items[i].selectedIcon,
                label: _items[i].label,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: FilledButton.icon(
                onPressed: onNewProject,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar Proyecto'),
              ),
            ),
            const Divider(height: 1),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline),
                  color: azureOnSurfaceVariant,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Soporte',
                  style: TextStyle(
                    fontSize: 12,
                    color: azureOnSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  color: azureError,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? azureSecondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected
                      ? azureOnSecondaryContainer
                      : azureOnSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: selected ? azureOnSecondaryContainer : azureOnSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationRequest extends StatelessWidget {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const NavigationRequest({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
    );
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DashboardError(message: error.toString()),
        data: (items) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(items: items),
                    const SizedBox(height: 32),
                    if (isDesktop)
                      _DesktopBento(items: items)
                    else
                      _StackedBento(items: items),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final List<DashboardItem> items;

  const _DashboardHeader({required this.items});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de Proyectos',
          style: TextStyle(
            fontSize: isMobile ? 28 : 32,
            fontWeight: FontWeight.w600,
            color: azureOnSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Supervisión en tiempo real de tu cartera de proyectos.',
          style: TextStyle(
            fontSize: 16,
            color: azureOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filtros'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exportación de datos próximamente.'),
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Exportar CSV'),
            ),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ProyectoFormDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo Proyecto'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopBento extends ConsumerWidget {
  final List<DashboardItem> items;

  const _DesktopBento({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: _HighlightCard(item: items[0])),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _MetricCard(item: items[1], spec: _metricSpecs[1])),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _MetricCard(item: items[2], spec: _metricSpecs[2])),
            ],
          ),
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: _MetricCard(item: items[3], spec: _metricSpecs[3])),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: const _RegionalCard()),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: const _RegistrationCard()),
            ],
          ),
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 8, child: const _RecentProjectsCard()),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: const _TelemetryCard()),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _AlertsPanel(),
      ],
    );
  }
}

class _StackedBento extends ConsumerWidget {
  final List<DashboardItem> items;

  const _StackedBento({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = Responsive.isTablet(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isTablet ? constraints.maxWidth / 2 - 12 : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HighlightCard(item: items[0]),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(item: items[1], spec: _metricSpecs[1]),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(item: items[2], spec: _metricSpecs[2]),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(item: items[3], spec: _metricSpecs[3]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _RegionalCard(),
            const SizedBox(height: 24),
            const _RegistrationCard(),
            const SizedBox(height: 24),
            const _RecentProjectsCard(),
            const SizedBox(height: 24),
            const _TelemetryCard(),
            const SizedBox(height: 24),
            const _AlertsPanel(),
          ],
        );
      },
    );
  }
}

class _MetricSpec {
  final IconData icon;
  final Color badge;
  final Color accent;
  final double progress;
  final String delta;

  const _MetricSpec({
    required this.icon,
    required this.badge,
    required this.accent,
    required this.progress,
    required this.delta,
  });
}

const _metricSpecs = [
  _MetricSpec(
    icon: Icons.people_outline,
    badge: azureSecondaryContainer,
    accent: azurePrimary,
    progress: 0.75,
    delta: '+3.2%',
  ),
  _MetricSpec(
    icon: Icons.payments_outlined,
    badge: azureTertiaryContainer,
    accent: azureTertiary,
    progress: 0.42,
    delta: '+12%',
  ),
  _MetricSpec(
    icon: Icons.apartment_outlined,
    badge: azureSecondaryContainer,
    accent: azurePrimary,
    progress: 0.63,
    delta: '+2.4%',
  ),
  _MetricSpec(
    icon: Icons.task_alt,
    badge: azureErrorContainer,
    accent: azureError,
    progress: 0.28,
    delta: 'Prioridad',
  ),
];

class _HighlightCard extends StatelessWidget {
  final DashboardItem item;

  const _HighlightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: const BoxDecoration(
        color: azurePrimaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -32,
            child: Icon(
              Icons.apartment,
              size: 220,
              color: azureOnPrimaryContainer.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISIÓN GENERAL',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                    color: azureOnPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: azureOnPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 48,
                            height: 1,
                            fontWeight: FontWeight.w400,
                            color: azureOnPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+2.4% vs trimestre anterior',
                          style: TextStyle(
                            fontSize: 12,
                            color: azureOnPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isMobile)
                      FilledButton(
                        onPressed: () {
                          context.mounted
                              ? ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Detalles del sistema próximamente.',
                                    ),
                                  ),
                                )
                              : null;
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: azureOnPrimaryContainer,
                          foregroundColor: azurePrimaryContainer,
                        ),
                        child: const Text('Ver Detalles'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final DashboardItem item;
  final _MetricSpec spec;

  const _MetricCard({required this.item, required this.spec});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: spec.badge,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(spec.icon, size: 20, color: spec.accent),
              ),
              const Spacer(),
              Text(
                spec.delta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: spec.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              color: azureOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: azureOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: spec.progress,
              minHeight: 4,
              color: spec.accent,
              backgroundColor: azureSurfaceContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalCard extends StatelessWidget {
  const _RegionalCard();

  static const _regions = [
    ('Bogotá', '120 sitios', 0.72),
    ('Medellín', '84 sitios', 0.5),
    ('Cali', '56 sitios', 0.33),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Alcance Regional',
      trailing: const Icon(Icons.map_outlined, color: azureOnSurfaceVariant),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _regions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _regions[i].$1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: azureOnSurface,
                        ),
                      ),
                      Text(
                        _regions[i].$2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: azureOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _regions[i].$3,
                      minHeight: 4,
                      color: azurePrimary,
                      backgroundColor: azureSurfaceContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Progreso de Registro',
      child: Column(
        children: const [
          _StepperStep(
            number: '1',
            title: 'Validación de Entidad',
            subtitle: 'Documentos corporativos verificados',
            done: true,
            isLast: false,
          ),
          _StepperStep(
            number: '2',
            title: 'Evaluación del Sitio',
            subtitle: 'Impacto ambiental aprobado',
            done: true,
            isLast: false,
          ),
          _StepperStep(
            number: '3',
            title: 'Asignación de Presupuesto',
            subtitle: 'En espera de firma',
            done: false,
            isLast: false,
          ),
          _StepperStep(
            number: '4',
            title: 'Adquisición de Recursos',
            subtitle: 'Pendiente del paso 3',
            done: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StepperStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool done;
  final bool isLast;

  const _StepperStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? azurePrimary : Colors.transparent,
                    border: Border.all(
                      color: done ? azurePrimary : azureOutlineVariant,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: azureOnPrimary,
                        )
                      : Center(
                          child: Text(
                            number,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: azureOnSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: azureOutlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: azureOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: azureOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectsCard extends ConsumerWidget {
  const _RecentProjectsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosProvider);

    return _Panel(
      title: 'Proyectos Recientes',
      trailing: TextButton(
        onPressed: () {
          ref.read(selectedMenuIndexProvider.notifier).set(1);
        },
        child: const Text('Ver todos'),
      ),
      child: proyectosAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: LinearProgressIndicator(),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudieron cargar los proyectos: $error',
            style: const TextStyle(color: azureError),
          ),
        ),
        data: (proyectos) {
          if (proyectos.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aún no hay proyectos registrados.',
                style: TextStyle(color: azureOnSurfaceVariant),
              ),
            );
          }
          return Column(
            children: [
              for (final proyecto in proyectos.take(4))
                _ProjectRow(proyecto: proyecto),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Proyecto proyecto;

  const _ProjectRow({required this.proyecto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: azureOutlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: azureSecondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.domain,
              size: 18,
              color: azurePrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              proyecto.descripcion ?? 'Sin descripción',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: azureOnSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              proyecto.ubicacionPrincipal ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: azureOnSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '\$${proyecto.precioDesde ?? 0} - \$${proyecto.precioHasta ?? 0}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: azureOnSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StatusPill(estado: proyecto.estado),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String? estado;

  const _StatusPill({required this.estado});

  @override
  Widget build(BuildContext context) {
    final text = estado ?? 'Sin estado';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: azureSecondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: azureOnSecondaryContainer,
        ),
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard();

  static const _heights = [0.5, 0.75, 0.33, 0.66, 1.0, 0.5, 0.6, 0.25, 0.8, 0.5];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Telemetría en Vivo',
      trailing: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: azureError,
          shape: BoxShape.circle,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in _heights)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: azurePrimary.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      height: h * 120,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sensores activos en 12 sectores',
            style: TextStyle(
              fontSize: 12,
              color: azureOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel();

  static const _alerts = [
    (
      title: 'Escasez de material en el sector 7',
      subtitle: 'El suministro de concreto se retrasa 48 horas.',
      time: 'Hace 15 minutos',
      color: azureError,
    ),
    (
      title: 'Advertencia de vencimiento de permiso',
      subtitle: 'Los permisos del puente vencen en 30 días.',
      time: 'Hace 2 horas',
      color: azureTertiary,
    ),
    (
      title: 'Documento de cumplimiento subido',
      subtitle: 'Global Infra Ltd presentó auditorías de seguridad.',
      time: 'Hace 5 horas',
      color: azurePrimary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final tiles = _alerts
        .map(
          (a) => _AlertTile(
            title: a.title,
            subtitle: a.subtitle,
            time: a.time,
            color: a.color,
          ),
        )
        .toList();

    return _Panel(
      title: 'Alertas Recientes',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (isDesktop) ...[
              Expanded(child: tiles[i]),
              if (i < tiles.length - 1) const SizedBox(width: 12),
            ] else ...[
              Flexible(child: tiles[i]),
              if (i < tiles.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _AlertTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: azureOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: azureOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: azureOutline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;

  const _Panel({this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.fromBorderSide(BorderSide(color: azureOutlineVariant)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: azureOnSurface,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (title != null) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  const _DashboardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: azureError),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el panel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: azureOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: azureOnSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class ProyectosView extends ConsumerWidget {
  const ProyectosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMobile ? 'Proyectos' : 'Gestión de Proyectos',
          style: TextStyle(fontSize: isMobile ? 20 : 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isMobile
                ? IconButton.filled(
                    onPressed: () => _showProyectoForm(context, ref),
                    icon: const Icon(Icons.add),
                  )
                : FilledButton.icon(
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
            padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
            itemCount: proyectos.length,
            separatorBuilder: (_, __) => SizedBox(height: isMobile ? 8 : 16),
            itemBuilder: (context, index) {
              final proyecto = proyectos[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  leading: proyecto.fotos != null && proyecto.fotos!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            proyecto.fotos!.first,
                            width: isMobile ? 50 : 60,
                            height: isMobile ? 50 : 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Icon(Icons.business, size: isMobile ? 32 : 40),
                  title: Text(
                    proyecto.descripcion ?? 'Sin descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Ubicación: ${proyecto.ubicacionPrincipal ?? "N/A"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      Text(
                        'Precio: \$${proyecto.precioDesde} - \$${proyecto.precioHasta}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: '',
                    onSelected: (value) {
                      switch (value) {
                        case 'editar':
                          _showProyectoForm(context, ref, proyecto: proyecto);
                        case 'eliminar':
                          _confirmDelete(context, ref, proyecto);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showProyectoForm(context, ref, proyecto: proyecto),
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

  void _showProyectoForm(
    BuildContext context,
    WidgetRef ref, {
    Proyecto? proyecto,
  }) {
    showDialog(
      context: context,
      builder: (context) => ProyectoFormDialog(proyecto: proyecto),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Proyecto proyecto,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${proyecto.descripcion ?? 'Sin descripción'}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteProyecto(context, ref, proyecto);
    }
  }

  Future<void> _deleteProyecto(
    BuildContext context,
    WidgetRef ref,
    Proyecto proyecto,
  ) async {
    try {
      await Supabase.instance.client
          .from('proyectos')
          .delete()
          .eq('id', proyecto.id);
      ref.invalidate(proyectosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto eliminado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class ProyectoFormDialog extends ConsumerStatefulWidget {
  final Proyecto? proyecto;

  const ProyectoFormDialog({super.key, this.proyecto});

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
  final _financiacionController = TextEditingController(text: 'Sí');
  final _subsidioController = TextEditingController(text: 'Sí');
  DateTime? _fechaFinalizacion;
  String? _selectedConstructoraId;

  late List<String> _existingImages;
  Proyecto? get _proyecto => widget.proyecto;
  bool get _isEditing => widget.proyecto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proyecto;
    _selectedConstructoraId = p?.constructoraId;
    _existingImages = List.of(p?.fotos ?? const []);
    if (p == null) return;
    _descripcionController.text = p.descripcion ?? '';
    _ubicacionController.text = p.ubicacionPrincipal ?? '';
    _precioDesdeController.text = p.precioDesde?.toString() ?? '';
    _precioHastaController.text = p.precioHasta?.toString() ?? '';
    _habitacionesController.text = p.habitaciones?.toString() ?? '';
    _banosController.text = p.banos?.toString() ?? '';
    _pisosController.text = p.cantidadPisos?.toString() ?? '';
    _estratoController.text = p.estrato?.toString() ?? '';
    _areaController.text = p.area?.toString() ?? '';
    _tipoPropiedadController.text = p.tipoPropiedad ?? 'Apartamento';
    _estadoController.text = p.estado ?? 'Sobre planos';
    _videoUrlController.text = p.videoUrl ?? '';
    _latController.text = p.lat?.toString() ?? '';
    _lngController.text = p.lng?.toString() ?? '';
    _financiacionController.text = (p.financiacion ?? false) ? 'Sí' : 'No';
    _subsidioController.text = (p.aplicaSubsidio ?? false) ? 'Sí' : 'No';
    _fechaFinalizacion = p.fechaFinalizacion;
    final amenidades = p.amenidades?['items'] ?? p.caracteristicas;
    if (amenidades is List) {
      _amenidadesSeleccionadas
        ..clear()
        ..addAll(amenidades.map((e) => e.toString()));
    }
  }

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
    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Proyecto' : 'Nuevo Proyecto'),
      content: SizedBox(
        width: isMobile ? width * 0.9 : 600,
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Constructora',
                          prefixIcon: Icon(Icons.business_center),
                        ),
                        items: constructoras
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                if (isMobile) ...[
                  TextFormField(
                    controller: _precioDesdeController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Desde',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _precioHastaController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Hasta',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ] else
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
                if (isMobile) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _financiacionController.text,
                    decoration: const InputDecoration(
                      labelText: 'Aplica Financiación',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sí', child: Text('Sí')),
                      DropdownMenuItem(value: 'No', child: Text('No')),
                    ],
                    onChanged: (v) =>
                        setState(() => _financiacionController.text = v!),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _subsidioController.text,
                    decoration: const InputDecoration(
                      labelText: 'Aplica Subsidio',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sí', child: Text('Sí')),
                      DropdownMenuItem(value: 'No', child: Text('No')),
                    ],
                    onChanged: (v) =>
                        setState(() => _subsidioController.text = v!),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _financiacionController.text,
                          decoration: const InputDecoration(
                            labelText: 'Aplica Financiación',
                          ),
                          items: const [
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
                          items: const [
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
                if (isMobile) ...[
                  TextFormField(
                    controller: _habitacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Habitaciones',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _banosController,
                    decoration: const InputDecoration(labelText: 'Baños'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pisosController,
                    decoration: const InputDecoration(labelText: 'Pisos'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _estratoController,
                    decoration: const InputDecoration(labelText: 'Estrato'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(labelText: 'Área (m²)'),
                    keyboardType: TextInputType.number,
                  ),
                ] else
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
                          decoration: const InputDecoration(
                            labelText: 'Estrato',
                          ),
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
                if (isMobile) ...[
                  TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitud',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitud',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ] else
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
                    ..._existingImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              entry.value,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
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
                                () => _existingImages.removeAt(entry.key),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
                  contentPadding: isMobile ? const EdgeInsets.all(12) : null,
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

      // 1. Subir las imágenes nuevas al Storage
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await supabase.storage
            .from('proyectos-fotos')
            .uploadBinary(
              fileName,
              _selectedImages[i],
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        uploadedUrls.add(
          supabase.storage
              .from('proyectos-fotos')
              .getPublicUrl(fileName),
        );
      }

      final values = <String, dynamic>{
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
        'video_url': _videoUrlController.text.trim(),
        'lat': double.tryParse(_latController.text),
        'lng': double.tryParse(_lngController.text),
        'estrato': int.tryParse(_estratoController.text),
        'cantidad_pisos': int.tryParse(_pisosController.text),
        'amenidades': {'items': _amenidadesSeleccionadas},
        'financiacion': _financiacionController.text == 'Sí',
        'aplica_subsidio': _subsidioController.text == 'Sí',
        'fecha_finalizacion': _fechaFinalizacion?.toIso8601String(),
      };

      // 2. Editar o crear en la DB
      if (_isEditing) {
        values['fotos'] = [..._existingImages, ...uploadedUrls];
        if (_selectedConstructoraId != null) {
          values['constructora_id'] = _selectedConstructoraId;
        }
        await supabase.from('proyectos').update(values).eq('id', _proyecto!.id);
      } else {
        values['fotos'] = uploadedUrls;
        values['constructora_id'] = _selectedConstructoraId;
        await supabase.from('proyectos').insert(values);
      }

      ref.invalidate(proyectosProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Proyecto actualizado exitosamente'
                  : 'Proyecto creado exitosamente',
            ),
          ),
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
