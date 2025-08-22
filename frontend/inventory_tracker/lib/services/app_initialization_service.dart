import 'package:inventory_tracker/domain/repositories/auth_repository.dart';
import 'package:inventory_tracker/data/repositories/product_repository_impl.dart';

class AppInitializationService {
  final AuthRepository authRepository;
  final ProductRepositoryImpl productRepository;

  AppInitializationService({
    required this.authRepository,
    required this.productRepository,
  });

  Future<bool> initializeApp() async {
    try {
      final token = await authRepository.getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      try {
        final user = await authRepository.getUserFromToken();
      } catch (e) {
        await authRepository.logout();
        return false;
      }

      productRepository.updateDataSource(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> onLoginSuccess(String token) async {
    productRepository.updateDataSource(token);
  }

  Future<void> onLogout() async {
    await authRepository.logout();
  }
}
