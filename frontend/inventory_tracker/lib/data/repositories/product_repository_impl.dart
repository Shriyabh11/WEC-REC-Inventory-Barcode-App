import 'package:inventory_tracker/data/datasources/product_remote_datasource.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRemoteDataSource? _remoteDataSource;
  ProductRepositoryImpl();

  void updateDataSource(String token) {
    _remoteDataSource = ProductRemoteDataSource(token);
  }

  @override
  Future<List<ProductEntity>> getProducts() async {
    if (_remoteDataSource == null) {
      throw Exception(
          'Repository not initialized - please ensure user is authenticated');
    }

    try {
      final products = await _remoteDataSource!.getProducts();
      return products.map((e) => ProductEntity.fromMap(e)).toList();
    } catch (e) {
      if (e.toString().contains('422')) {
        throw Exception('Authentication failed - please log in again');
      } else if (e.toString().contains('401')) {
        throw Exception('Unauthorized - invalid or expired token');
      } else if (e.toString().contains('403')) {
        throw Exception('Access forbidden - insufficient permissions');
      } else if (e.toString().contains('404')) {
        throw Exception('Products endpoint not found');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error - please try again later');
      } else if (e.toString().contains('Network error')) {
        throw Exception('Network connection failed - check your internet');
      }

      throw Exception('Failed to load products: $e');
    }
  }

  @override
  Future<ProductEntity> createProduct(
      String name, String description, int threshold,
      [String? imagePath]) async {
    if (_remoteDataSource == null) {
      throw Exception(
          'Repository not initialized - please ensure user is authenticated');
    }

    try {
      final response = await _remoteDataSource!.createProduct(
        name,
        description,
        threshold,
        imagePath: imagePath,
      );

      final product = response['product'];

      if (product == null || product['id'] == null) {
        throw Exception('Product creation failed - invalid server response');
      }

      return ProductEntity.fromMap(product);
    } catch (e) {
      if (e.toString().contains('422')) {
        throw Exception('Invalid product data - please check all fields');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentication required - please log in again');
      } else if (e.toString().contains('409')) {
        throw Exception('Product with this name already exists');
      }

      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> receiveItem(int productId) async {
    if (_remoteDataSource == null) {
      throw Exception(
          'Repository not initialized - please ensure user is authenticated');
    }

    try {
      final result = await _remoteDataSource!.receiveItem(productId);
      return result;
    } catch (e) {
      if (e.toString().contains('404')) {
        throw Exception('Product not found');
      } else if (e.toString().contains('422')) {
        throw Exception('Unable to receive item - invalid request');
      }

      throw Exception('Failed to receive item: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> dispatchItem(String barcodeData) async {
    if (_remoteDataSource == null) {
      throw Exception(
          'Repository not initialized - please ensure user is authenticated');
    }

    try {
      final result = await _remoteDataSource!.dispatchItem(barcodeData);
      return result;
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Invalid barcode data');
      } else if (e.toString().contains('404')) {
        throw Exception('Item not found');
      } else if (e.toString().contains('409')) {
        throw Exception('Item already dispatched');
      }

      throw Exception('Failed to dispatch item: $e');
    }
  }

  @override
  Future<List<AlertEntity>> getAlerts() async {
    if (_remoteDataSource == null) {
      throw Exception(
          'Repository not initialized - please ensure user is authenticated');
    }

    try {
      final alerts = await _remoteDataSource!.getAlerts();
      return alerts.map((e) => AlertEntity.fromMap(e)).toList();
    } catch (e) {
      if (e.toString().contains('422')) {
        throw Exception('Authentication failed - please log in again');
      }

      throw Exception('Failed to load alerts: $e');
    }
  }
}
