import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts();
  Future<ProductEntity> createProduct(String name, String description, int threshold);
  Future<Map<String, dynamic>> receiveItem(int productId);
  Future<Map<String, dynamic>> dispatchItem(String barcodeData);
   Future<List<AlertEntity>> getAlerts();
}