import 'package:equatable/equatable.dart';
import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';



class DispatchItem extends Usecase<Map<String, dynamic>, DispatchItemParams> {
  final ProductRepository repository;

  DispatchItem(this.repository);

  @override
  Future<Map<String, dynamic>> call(DispatchItemParams params) async {
    return await repository.dispatchItem(params.barcodeData);
  }
}

class DispatchItemParams extends Equatable {
  final String barcodeData;

  const DispatchItemParams({required this.barcodeData});

  @override
  List<Object?> get props => [barcodeData];
}