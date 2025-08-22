import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/repositories/auth_repository.dart';

class CheckAuthStatus extends Usecase<bool, NoParams> {
  final AuthRepository repository;

  CheckAuthStatus(this.repository);

  @override
  Future<bool> call(NoParams params) async {
    final token = await repository.getToken();
    return token != null;
  }
}
