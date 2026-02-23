import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vihomeweb/domain/dashboard_item.dart';

final dashboardProvider = FutureProvider<List<DashboardItem>>((ref) async {
  // In a real application, you would fetch this data from Supabase
  await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
  return [
    DashboardItem(title: 'Users', value: '1,234'),
    DashboardItem(title: 'Sales', value: '\$56,789'),
    DashboardItem(title: 'Active Projects', value: '42'),
    DashboardItem(title: 'Pending Tasks', value: '12'),
  ];
});
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).value?.session;
});
