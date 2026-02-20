import '../datasources/auth_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<UserEntity?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return dataSource.loginWithEmail(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    await dataSource.logout();
  }
}
