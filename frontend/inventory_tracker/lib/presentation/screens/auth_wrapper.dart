import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/presentation/screens/dashboard_screen.dart';
import 'package:inventory_tracker/presentation/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (state is AuthenticatedState) {
          return const DashboardScreen();
        } else {
          return const DashboardScreen();
        }
      },
    );
  }
}
