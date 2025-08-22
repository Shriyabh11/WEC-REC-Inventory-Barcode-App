import 'package:inventory_tracker/core/usecases/usecases.dart';
import 'package:inventory_tracker/domain/repositories/auth_repository.dart';

class LogoutUser extends Usecase<void, NoParams> {
  final AuthRepository repository;

  LogoutUser(this.repository);

  @override
  Future<void> call(NoParams params) async {
    await repository.logout();
  }
}
