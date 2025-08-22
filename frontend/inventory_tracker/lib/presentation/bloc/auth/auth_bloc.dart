import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/domain/entities/user_entity.dart';
import 'package:inventory_tracker/domain/repositories/auth_repository.dart';
import 'package:inventory_tracker/services/app_initialization_service.dart';

// Events
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

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated({required this.user});
  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final AppInitializationService? appInitService;

  AuthBloc({
    required this.authRepository,
    this.appInitService,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginEvent>(_onLoginEvent);
    on<RegisterEvent>(_onRegisterEvent);
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (appInitService != null) {
        final isAuthenticated = await appInitService!.initializeApp();
        if (isAuthenticated) {
          final user = await authRepository.getUserFromToken();
          emit(Authenticated(user: user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        final token = await authRepository.getToken();
        if (token != null && token.isNotEmpty) {
          try {
            final user = await authRepository.getUserFromToken();
            emit(Authenticated(user: user));
          } catch (e) {
            await authRepository.logout();
            emit(Unauthenticated());
          }
        } else {
          emit(Unauthenticated());
        }
      }
    } catch (e) {
      emit(AuthFailure('Failed to initialize app: $e'));
    }
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      if (appInitService != null) {
        final token = await authRepository.getToken();
        if (token != null) {
          await appInitService!.onLoginSuccess(token);
        }
      }
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          'Login failed: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> _onRegisterEvent(
      RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(event.email, event.password);
      if (appInitService != null) {
        final token = await authRepository.getToken();
        if (token != null) {
          await appInitService!.onLoginSuccess(token);
        }
      }
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          'Registration failed: ${e.toString().replaceAll('Exception: ', '')}'));
    }
  }

  Future<void> _onLogoutEvent(
      LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      if (appInitService != null) {
        await appInitService!.onLogout();
      } else {
        await authRepository.logout();
      }
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Logout failed: $e'));
    }
  }
}
