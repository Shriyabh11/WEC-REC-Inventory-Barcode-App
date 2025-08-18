import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/datasources/auth_remote_datasource.dart';
import 'package:inventory_tracker/datasources/product_remote_datasource.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:inventory_tracker/presentation/screens/auth_wrapper.dart';
import 'package:inventory_tracker/repositories/auth_repository_impl.dart';
import 'package:inventory_tracker/repositories/product_repository_impl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(AuthRemoteDataSource()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepositoryImpl>(context),
            )..add(AppStarted()),
          ),
          BlocProvider<ProductBloc>(
            create: (context) {
              final authBloc = context.read<AuthBloc>();
              return ProductBloc(
                productRepository: ProductRepositoryImpl(
                  ProductRemoteDataSource('DUMMY_TOKEN') // Dummy token for initial setup
                ),
                authBloc: authBloc,
              );
            },
          ),
        ],
        child: MaterialApp(
          title: 'Inventory Scanner',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
