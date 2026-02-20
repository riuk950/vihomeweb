import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl(this.supabaseClient);

  @override
  Future<UserEntity?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      return UserEntity(
        id: response.user!.id,
        email: response.user!.email ?? '',
      );
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }
}
