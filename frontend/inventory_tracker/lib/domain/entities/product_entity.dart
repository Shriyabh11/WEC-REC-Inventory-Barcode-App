import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String description;
  final int quantity;
  final int threshold;
  final bool isLowStock;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.threshold,
    required this.isLowStock,
  });

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      threshold: map['threshold'] ?? 0,
      isLowStock: map['is_low_stock'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, description, quantity, threshold, isLowStock];
}
