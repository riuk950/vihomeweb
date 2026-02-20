import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/exceptions/auth_exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;

  LoginCubit({required this.loginUseCase}) : super(LoginInitial());

  Future<void> login(String email, String password) async {
    // Validación básica
    if (email.isEmpty || password.isEmpty) {
      emit(const LoginFailure('Email y contraseña son requeridos.'));
      return;
    }

    emit(LoginLoading());
    try {
      final user = await loginUseCase(email: email, password: password);
      if (user != null) {
        emit(LoginSuccess(user));
      } else {
        emit(const LoginFailure('No se pudo completar el login.'));
      }
    } on InvalidCredentialsException catch (e) {
      emit(LoginFailure(e.message));
    } on NetworkException catch (e) {
      emit(LoginFailure(e.message));
    } on UnauthorizedException catch (e) {
      emit(LoginFailure(e.message));
    } on UnknownAuthException catch (e) {
      emit(LoginFailure(e.message));
    } catch (e) {
      emit(LoginFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
