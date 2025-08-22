import 'package:inventory_tracker/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String email, String password);
  Future<void> logout();
  Future<String?> getToken();
  Future<UserEntity> getUserFromToken();
}
