import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/data/repositories/auth_repository_impl.dart';
import 'package:inventory_tracker/data/repositories/product_repository_impl.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/usecases/product/create_product.dart';
import 'package:inventory_tracker/domain/usecases/product/dispatch_item.dart';
import 'package:inventory_tracker/domain/usecases/product/get_alerts.dart';
import 'package:inventory_tracker/domain/usecases/product/get_products.dart';
import 'package:inventory_tracker/domain/usecases/product/recieve_item.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object> get props => [];
}

class FetchProductsEvent extends ProductEvent {}

class CreateProductEvent extends ProductEvent {
  final String name;
  final String description;
  final int threshold;
  final String? imagePath;
  const CreateProductEvent({
    required this.name,
    required this.description,
    required this.threshold,
    this.imagePath,
  });
  @override
  List<Object> get props => [name, description, threshold, imagePath ?? ''];
}

class ReceiveItemEvent extends ProductEvent {
  final int productId;
  const ReceiveItemEvent({required this.productId});
  @override
  List<Object> get props => [productId];
}

class DispatchItemEvent extends ProductEvent {
  final String barcodeData;
  const DispatchItemEvent({required this.barcodeData});
  @override
  List<Object> get props => [barcodeData];
}

class FetchAlertsEvent extends ProductEvent {}

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoadingState extends ProductState {}

class ProductsLoadedState extends ProductState {
  final List<ProductEntity> products;
  final List<AlertEntity> alerts;
  final Map<String, dynamic>? barcodeResponse;
  const ProductsLoadedState({
    this.products = const [],
    this.alerts = const [],
    this.barcodeResponse,
  });
  @override
  List<Object?> get props => [products, alerts, barcodeResponse];
}

class ProductErrorState extends ProductState {
  final String message;
  const ProductErrorState(this.message);
  @override
  List<Object> get props => [message];
}

class ProductActionSuccessState extends ProductState {
  final String message;
  final List<ProductEntity> products;
  final List<AlertEntity> alerts;

  const ProductActionSuccessState({
    required this.message,
    required this.products,
    required this.alerts,
  });

  @override
  List<Object> get props => [message, products, alerts];
}

class ProductCreatedState extends ProductState {
  final ProductEntity product;
  const ProductCreatedState(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepositoryImpl productRepository;
  final AuthBloc authBloc;

  ProductBloc({required this.productRepository, required this.authBloc})
      : super(ProductInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<CreateProductEvent>(_onCreateProduct);
    on<ReceiveItemEvent>(_onReceiveItem);
    on<DispatchItemEvent>(_onDispatchItem);
    on<FetchAlertsEvent>(_onFetchAlerts);

    authBloc.stream.listen((authState) async {
      if (authState is Authenticated) {
        AuthRepositoryImpl authRepository =
            GetIt.instance<AuthRepositoryImpl>();
        final token = await authRepository.getToken();
        if (token != null) {
          productRepository.updateDataSource(token);
          add(FetchProductsEvent());
        }
      } else if (authState is Unauthenticated) {
        add(FetchProductsEvent());
      }
    });
  }

  Future<void> _onFetchProducts(
      FetchProductsEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoadingState());
    try {
      final getProductsUsecase = GetProducts(productRepository);
      final products = await getProductsUsecase.call(NoParams());
      final getAlertsUsecase = GetAlerts(productRepository);
      final alerts = await getAlertsUsecase.call(NoParams());
      emit(ProductsLoadedState(products: products, alerts: alerts));
    } catch (e) {
      emit(ProductErrorState('Failed to fetch products: $e'));
    }
  }

  Future<void> _onCreateProduct(
      CreateProductEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoadingState());
    try {
      final createProductUsecase = CreateProduct(productRepository);
      final createdProduct = await createProductUsecase.call(
        CreateProductParams(
          name: event.name,
          description: event.description,
          threshold: event.threshold,
          imagePath: event.imagePath,
        ),
      );

      emit(ProductCreatedState(createdProduct));

      final products = await GetProducts(productRepository).call(NoParams());
      final alerts = await GetAlerts(productRepository).call(NoParams());
      emit(ProductsLoadedState(products: products, alerts: alerts));
    } catch (e) {
      try {
        final products = await GetProducts(productRepository).call(NoParams());
        final alerts = await GetAlerts(productRepository).call(NoParams());
        emit(ProductsLoadedState(products: products, alerts: alerts));
      } catch (fetchError) {}
      emit(ProductErrorState('Failed to create product: $e'));
    }
  }

  Future<void> _onReceiveItem(
      ReceiveItemEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoadingState());
    try {
      final receiveItemUsecase = ReceiveItem(productRepository);
      final response = await receiveItemUsecase
          .call(ReceiveItemParams(productId: event.productId));

      final products = await GetProducts(productRepository).call(NoParams());
      final alerts = await GetAlerts(productRepository).call(NoParams());

      emit(ProductsLoadedState(
        products: products,
        alerts: alerts,
        barcodeResponse: response,
      ));
    } catch (e) {
      emit(ProductErrorState('Failed to receive item: $e'));

      if (state is ProductsLoadedState) {
        final currentState = state as ProductsLoadedState;
        emit(ProductsLoadedState(
            products: currentState.products, alerts: currentState.alerts));
      }
    }
  }

  Future<void> _onDispatchItem(
      DispatchItemEvent event, Emitter<ProductState> emit) async {
    emit(ProductLoadingState());
    try {
      final dispatchItemUsecase = DispatchItem(productRepository);
      await dispatchItemUsecase
          .call(DispatchItemParams(barcodeData: event.barcodeData));

      final products = await GetProducts(productRepository).call(NoParams());
      final alerts = await GetAlerts(productRepository).call(NoParams());

      emit(ProductActionSuccessState(
        message: 'Item dispatched successfully!',
        products: products,
        alerts: alerts,
      ));
    } catch (e) {
      emit(ProductErrorState('Failed to dispatch item: $e'));

      if (state is ProductsLoadedState) {
        final currentState = state as ProductsLoadedState;
        emit(ProductsLoadedState(
            products: currentState.products, alerts: currentState.alerts));
      }
    }
  }

  Future<void> _onFetchAlerts(
      FetchAlertsEvent event, Emitter<ProductState> emit) async {
    try {
      final getAlertsUsecase = GetAlerts(productRepository);
      final alerts = await getAlertsUsecase.call(NoParams());
      if (state is ProductsLoadedState) {
        final currentState = state as ProductsLoadedState;
        emit(ProductsLoadedState(
            products: currentState.products, alerts: alerts));
      }
    } catch (e) {
      emit(ProductErrorState('Failed to fetch alerts: $e'));
    }
  }
}
