import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:inventory_tracker/data/datasources/auth_remote_datasource.dart';
import 'package:inventory_tracker/data/repositories/auth_repository_impl.dart';
import 'package:inventory_tracker/data/repositories/product_repository_impl.dart';
import 'package:inventory_tracker/domain/repositories/auth_repository.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:inventory_tracker/presentation/screens/app_wrapper.dart';
import 'package:inventory_tracker/services/app_initialization_service.dart';

void setupServiceLocator() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.reset();
  }
  getIt.registerSingleton<AuthRemoteDataSource>(AuthRemoteDataSource());

  getIt.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(getIt<AuthRemoteDataSource>()));

  getIt.registerSingleton<ProductRepositoryImpl>(ProductRepositoryImpl());

  getIt.registerSingleton<AppInitializationService>(AppInitializationService(
    authRepository: getIt<AuthRepository>(),
    productRepository: getIt<ProductRepositoryImpl>(),
  ));
}

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: GetIt.instance<AuthRepository>(),
            appInitService: GetIt.instance<AppInitializationService>(),
          )..add(AppStarted()),
        ),
        BlocProvider<ProductBloc>(
          create: (context) {
            final authBloc = context.read<AuthBloc>();
            return ProductBloc(
              productRepository: GetIt.instance<ProductRepositoryImpl>(),
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
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
