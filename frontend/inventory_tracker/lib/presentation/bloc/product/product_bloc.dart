import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/datasources/product_remote_datasource.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/usecases/product/create_product.dart';
import 'package:inventory_tracker/domain/usecases/product/dispatch_item.dart';
import 'package:inventory_tracker/domain/usecases/product/get_alerts.dart';
import 'package:inventory_tracker/domain/usecases/product/get_products.dart';
import 'package:inventory_tracker/domain/usecases/product/recieve_item.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/repositories/product_repository_impl.dart';



// Events
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
  const CreateProductEvent({required this.name, required this.description, required this.threshold});
  @override
  List<Object> get props => [name, description, threshold];
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


// States
abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoadingState extends ProductState {}
class ProductsLoadedState extends ProductState {
  final List<ProductEntity> products;
  final List<ProductEntity> alerts;
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

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepositoryImpl productRepository;
  final AuthBloc authBloc;

  ProductBloc({required this.productRepository, required this.authBloc}) : super(ProductInitial()) {
    on<FetchProductsEvent>(_onFetchProducts);
    on<CreateProductEvent>(_onCreateProduct);
    on<ReceiveItemEvent>(_onReceiveItem);
    on<DispatchItemEvent>(_onDispatchItem);
    on<FetchAlertsEvent>(_onFetchAlerts);

    authBloc.stream.listen((authState) {
      if (authState is AuthenticatedState) {
        final token = authState.user.id.toString();
        productRepository.remoteDataSource = ProductRemoteDataSource(token);
        add(FetchProductsEvent());
      } else if (authState is UnauthenticatedState) {
        productRepository.remoteDataSource = ProductRemoteDataSource('DUMMY_TOKEN');
        emit(const ProductsLoadedState(products: [], alerts: []));
      }
    });
  }

  Future<void> _onFetchProducts(FetchProductsEvent event, Emitter<ProductState> emit) async {
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

  Future<void> _onCreateProduct(CreateProductEvent event, Emitter<ProductState> emit) async {
    try {
      final createProductUsecase = CreateProduct(productRepository);
      await createProductUsecase.call(CreateProductParams(name: event.name, description: event.description, threshold: event.threshold));
      add(FetchProductsEvent()); // Refresh the list after creation
    } catch (e) {
      emit(ProductErrorState('Failed to create product: $e'));
    }
  }

  Future<void> _onReceiveItem(ReceiveItemEvent event, Emitter<ProductState> emit) async {
    try {
      final receiveItemUsecase = ReceiveItem(productRepository);
      final response = await receiveItemUsecase.call(ReceiveItemParams(productId: event.productId));
      
      final currentState = state as ProductsLoadedState;
      
      // Emit a new state with the barcode response data and the existing product lists
      emit(ProductsLoadedState(
        products: currentState.products, 
        alerts: currentState.alerts, 
        barcodeResponse: response,
      ));

      // After navigation, re-fetch products to update the list
      add(FetchProductsEvent());

    } catch (e) {
      emit(ProductErrorState('Failed to receive item: $e'));
    }
  }

  Future<void> _onDispatchItem(DispatchItemEvent event, Emitter<ProductState> emit) async {
    try {
      final dispatchItemUsecase = DispatchItem(productRepository);
      await dispatchItemUsecase.call(DispatchItemParams(barcodeData: event.barcodeData));
      add(FetchProductsEvent()); // Refresh the list
    } catch (e) {
      emit(ProductErrorState('Failed to dispatch item: $e'));
    }
  }

  Future<void> _onFetchAlerts(FetchAlertsEvent event, Emitter<ProductState> emit) async {
    try {
      final getAlertsUsecase = GetAlerts(productRepository);
      final alerts = await getAlertsUsecase.call(NoParams());
      if (state is ProductsLoadedState) {
        final currentState = state as ProductsLoadedState;
        emit(ProductsLoadedState(products: currentState.products, alerts: alerts));
      }
    } catch (e) {
      emit(ProductErrorState('Failed to fetch alerts: $e'));
    }
  }
}