import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/repositories/product_repository.dart';

class GetAlerts extends Usecase<List<AlertEntity>, NoParams> {
  final ProductRepository repository;

  GetAlerts(this.repository);

  @override
  Future<List<AlertEntity>> call(NoParams params) async {
    return await repository.getAlerts();
  }
}
