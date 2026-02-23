import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/domain/dashboard_item.dart';

import 'package:vihomeweb/domain/models/proyecto.dart';

final dashboardProvider = FutureProvider<List<DashboardItem>>((ref) async {
  // En una aplicación real, obtendrías estos datos de Supabase
  await Future.delayed(const Duration(seconds: 1)); // Simular retraso
  return [
    DashboardItem(title: 'Usuarios', value: '1,234'),
    DashboardItem(title: 'Ventas', value: '\$56,789'),
    DashboardItem(title: 'Proyectos Activos', value: '42'),
    DashboardItem(title: 'Tareas Pendientes', value: '12'),
  ];
});

final proyectosProvider = FutureProvider<List<Proyecto>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('proyectos')
      .select()
      .order('created_at');

  return (response as List).map((json) => Proyecto.fromJson(json)).toList();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).value?.session;
});
