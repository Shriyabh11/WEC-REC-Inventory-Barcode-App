import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/entities/user_entity.dart';
import 'package:inventory_tracker/domain/usecases/auth/check_auth_status.dart';
import 'package:inventory_tracker/domain/usecases/auth/login_user.dart';
import 'package:inventory_tracker/domain/usecases/auth/logout_user.dart';
import 'package:inventory_tracker/domain/usecases/auth/register_user.dart';
import 'package:inventory_tracker/repositories/auth_repository_impl.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  const RegisterEvent({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final UserEntity user;
  const AuthenticatedState(this.user);
  @override
  List<Object> get props => [user];
}

class UnauthenticatedState extends AuthState {}
class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginEvent>(_onLoginEvent);
    on<RegisterEvent>(_onRegisterEvent);
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final checkAuthStatusUsecase = CheckAuthStatus(authRepository);
    final isAuthenticated = await checkAuthStatusUsecase.call(NoParams());
    if (isAuthenticated) {
      // Logic to get user details would go here
      emit(const AuthenticatedState(UserEntity(id: 0, email: '')));
    } else {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final loginUsecase = LoginUser(authRepository);
      final user = await loginUsecase.call(LoginParams(email: event.email, password: event.password));
      emit(AuthenticatedState(user));
    } catch (e) {
      emit(const AuthErrorState('Login failed. Please check your credentials.'));
    }
  }

  Future<void> _onRegisterEvent(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    try {
      final registerUsecase = RegisterUser(authRepository);
      final user = await registerUsecase.call(RegisterParams(email: event.email, password: event.password));
      emit(AuthenticatedState(user));
    } catch (e) {
      emit(const AuthErrorState('Registration failed. Please try again.'));
    }
  }

  Future<void> _onLogoutEvent(LogoutEvent event, Emitter<AuthState> emit) async {
    final logoutUsecase = LogoutUser(authRepository);
    await logoutUsecase.call(NoParams());
    emit(UnauthenticatedState());
  }
}