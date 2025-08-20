import 'dart:developer' as developer;
import 'package:inventory_tracker/data/datasources/product_remote_datasource.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  // Method to update data source with new token
  void updateDataSource(String token) {
    developer.log('Updating ProductRepository with new token: ${token.substring(0, 10)}...', name: 'ProductRepo');
    remoteDataSource = ProductRemoteDataSource(token);
  }

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      developer.log('Fetching products from remote data source', name: 'ProductRepo');
      final products = await remoteDataSource.getProducts();
      developer.log('Successfully fetched ${products.length} products', name: 'ProductRepo');
      return products.map((e) => ProductEntity.fromMap(e)).toList();
    } catch (e) {
      developer.log('Error fetching products: $e', name: 'ProductRepo', level: 1000);
      
      // Enhanced error handling for different HTTP status codes
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
  Future<ProductEntity> createProduct(String name, String description, int threshold) async {
    try {
      developer.log('Creating product: $name', name: 'ProductRepo');
      final product = await remoteDataSource.createProduct(name, description, threshold);
      developer.log('Successfully created product with ID: ${product['id']}', name: 'ProductRepo');
      return ProductEntity.fromMap(product);
    } catch (e) {
      developer.log('Error creating product: $e', name: 'ProductRepo', level: 1000);
      
      if (e.toString().contains('422')) {
        throw Exception('Invalid product data - please check all fields');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentication required - please log in again');
      }
      
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> receiveItem(int productId) async {
    try {
      developer.log('Receiving item for product ID: $productId', name: 'ProductRepo');
      final result = await remoteDataSource.receiveItem(productId);
      developer.log('Successfully received item: ${result['item_id']}', name: 'ProductRepo');
      return result;
    } catch (e) {
      developer.log('Error receiving item: $e', name: 'ProductRepo', level: 1000);
      
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
    try {
      developer.log('Dispatching item with barcode: ${barcodeData.substring(0, 10)}...', name: 'ProductRepo');
      final result = await remoteDataSource.dispatchItem(barcodeData);
      developer.log('Successfully dispatched item', name: 'ProductRepo');
      return result;
    } catch (e) {
      developer.log('Error dispatching item: $e', name: 'ProductRepo', level: 1000);
      
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
    try {
      developer.log('Fetching alerts from remote data source', name: 'ProductRepo');
      final alerts = await remoteDataSource.getAlerts();
      developer.log('Successfully fetched ${alerts.length} alerts', name: 'ProductRepo');
      return alerts.map((e) => AlertEntity.fromMap(e)).toList();
    } catch (e) {
      developer.log('Error fetching alerts: $e', name: 'ProductRepo', level: 1000);
      
      if (e.toString().contains('422')) {
        throw Exception('Authentication failed - please log in again');
      }
      
      throw Exception('Failed to load alerts: $e');
    }
  }
}