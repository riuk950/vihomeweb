import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;

  LoginCubit({required this.loginUseCase}) : super(LoginInitial());

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    try {
      final user = await loginUseCase(email: email, password: password);
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(const LoginFailure('Credenciales inválidas'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
