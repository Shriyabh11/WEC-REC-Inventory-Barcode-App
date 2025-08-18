import 'package:equatable/equatable.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class CreateProduct extends Usecase<ProductEntity, CreateProductParams> {
  final ProductRepository repository;

  CreateProduct(this.repository);

  @override
  Future<ProductEntity> call(CreateProductParams params) async {
    return await repository.createProduct(
      params.name,
      params.description,
      params.threshold,
    );
  }
}

class CreateProductParams extends Equatable {
  final String name;
  final String description;
  final int threshold;

  const CreateProductParams({
    required this.name,
    required this.description,
    required this.threshold,
  });

  @override
  List<Object?> get props => [name, description, threshold];
}
