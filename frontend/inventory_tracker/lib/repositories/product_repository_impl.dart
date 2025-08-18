

import 'package:inventory_tracker/datasources/product_remote_datasource.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  late final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ProductEntity>> getProducts() async {
    final products = await remoteDataSource.getProducts();
    return products.map((e) => ProductEntity.fromMap(e)).toList();
  }

  @override
  Future<ProductEntity> createProduct(String name, String description, int threshold) async {
    final product = await remoteDataSource.createProduct(name, description, threshold);
    return ProductEntity.fromMap(product);
  }

  @override
  Future<Map<String, dynamic>> receiveItem(int productId) async {
    final response = await remoteDataSource.receiveItem(productId);
    return response;
  }

  @override
  Future<Map<String, dynamic>> dispatchItem(String barcodeData) async {
    final response = await remoteDataSource.dispatchItem(barcodeData);
    return response;
  }

  @override
  Future<List<ProductEntity>> getAlerts() async {
    final alerts = await remoteDataSource.getAlerts();
    return alerts.map((e) => ProductEntity.fromMap(e)).toList();
  }
}