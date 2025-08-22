class AlertEntity {
  final int productId;
  final String productName;
  final int currentQuantity;
  final int threshold;

  AlertEntity({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.threshold,
  });

  factory AlertEntity.fromMap(Map<String, dynamic> map) {
    return AlertEntity(
      productId: map['product_id'],
      productName: map['product_name'],
      currentQuantity: map['current_quantity'],
      threshold: map['threshold'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'current_quantity': currentQuantity,
      'threshold': threshold,
    };
  }
}
