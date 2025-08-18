import 'package:equatable/equatable.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class ReceiveItem extends Usecase<Map<String, dynamic>, ReceiveItemParams> {
  final ProductRepository repository;

  ReceiveItem(this.repository);

  @override
  Future<Map<String, dynamic>> call(ReceiveItemParams params) async {
    return await repository.receiveItem(params.productId);
  }
}

class ReceiveItemParams extends Equatable {
  final int productId;

  const ReceiveItemParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}