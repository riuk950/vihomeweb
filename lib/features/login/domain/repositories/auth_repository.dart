import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> loginWithEmail({
    required String email,
    required String password,
  });
  
  Future<void> logout();
}
