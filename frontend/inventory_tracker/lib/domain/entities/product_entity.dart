import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String description;
  final int quantity;
  final int threshold;
  final bool isLowStock;
  final List<ItemEntity> items;
  final String? imagePath;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.threshold,
    required this.isLowStock,
    required this.items,
    this.imagePath,
  });

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      threshold: map['threshold'] ?? 0,
      isLowStock: map['is_low_stock'] ?? false,
      items:
          (map['items'] as List?)?.map((i) => ItemEntity.fromMap(i)).toList() ??
              [],
      imagePath: map['image_path'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        quantity,
        threshold,
        isLowStock,
        items,
        imagePath
      ];
}

class ItemEntity extends Equatable {
  final int id;
  final String barcode;
  final String status;

  const ItemEntity(
      {required this.id, required this.barcode, required this.status});

  factory ItemEntity.fromMap(Map<String, dynamic> map) {
    return ItemEntity(
      id: map['id'],
      barcode: map['barcode'],
      status: map['status'],
    );
  }

  @override
  List<Object> get props => [id, barcode, status];
}
