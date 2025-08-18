
import 'package:inventory_tracker/datasources/auth_remote_datasource.dart';
import 'package:inventory_tracker/domain/entities/user_entity.dart';
import 'package:inventory_tracker/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    final response = await remoteDataSource.login(email, password);
    await remoteDataSource.saveToken(response['access_token']);
    return UserEntity.fromMap(response['user']);
  }

  @override
  Future<UserEntity> register(String email, String password) async {
    final response = await remoteDataSource.register(email, password);
    await remoteDataSource.saveToken(response['access_token']);
    return UserEntity.fromMap(response['user']);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.deleteToken();
  }

  @override
  Future<String?> getToken() async {
    return await remoteDataSource.getToken();
  }
}