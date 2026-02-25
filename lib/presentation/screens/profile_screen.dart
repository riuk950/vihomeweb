import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/data/providers.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session?.user;

    if (user == null) {
      return const Center(child: Text('No se ha iniciado sesión'));
    }

    final email = user.email ?? 'No disponible';
    final metadata = user.userMetadata ?? {};
    final name = metadata['full_name'] ?? 'Usuario VIHOME';
    final role = metadata['role'] ?? 'Sin rol';
    final lastSignIn = user.lastSignInAt != null
        ? DateTime.parse(user.lastSignInAt!).toLocal().toString().split('.')[0]
        : 'Desconocido';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(context, name, email),
                const SizedBox(height: 40),
                _buildInfoSection(context, user, role, lastSignIn),
                const SizedBox(height: 40),
                _buildSecuritySection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 60, color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            // Acción para editar perfil
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar Perfil'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    User user,
    String role,
    String lastSignIn,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Cuenta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              Icons.admin_panel_settings_outlined,
              'Rol del Usuario',
              role.toString().toUpperCase(),
            ),
            const Divider(height: 32),
            _buildInfoRow(
              context,
              Icons.badge_outlined,
              'ID de Usuario',
              user.id,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              context,
              Icons.history_outlined,
              'Último Inicio de Sesión',
              lastSignIn,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              context,
              Icons.verified_user_outlined,
              'Estado de Verificación',
              user.emailConfirmedAt != null ? 'Verificado' : 'Pendiente',
              color: user.emailConfirmedAt != null
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Cambiar Contraseña'),
            subtitle: const Text(
              'Actualiza tu contraseña para mantener tu cuenta segura',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Acción para cambiar contraseña
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
