import 'package:flutter/foundation.dart';
import 'package:inventory_tracker/services/app_initialization_service.dart';
import 'package:inventory_tracker/domain/entities/user_entity.dart';

class AuthStateManager extends ChangeNotifier {
  final AppInitializationService _appInitService;

  bool _isInitialized = false;
  bool _isAuthenticated = false;
  UserEntity? _currentUser;
  String? _errorMessage;

  AuthStateManager(this._appInitService);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  /// Initialize the app
  Future<void> initialize() async {
    try {
      _errorMessage = null;
      notifyListeners();

      final isAuthenticated = await _appInitService.initializeApp();

      if (isAuthenticated) {
        // Get current user data
        _currentUser = await _appInitService.authRepository.getUserFromToken();
      }

      _isInitialized = true;
      _isAuthenticated = isAuthenticated;
    } catch (e) {
      _isInitialized = true;
      _isAuthenticated = false;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Handle login
  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners();

      // Perform login
      final user = await _appInitService.authRepository.login(email, password);

      // Get the token and update repositories
      final token = await _appInitService.authRepository.getToken();
      if (token != null) {
        await _appInitService.onLoginSuccess(token);
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }

      throw Exception('Login succeeded but no token received');
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle logout
  Future<void> logout() async {
    await _appInitService.onLogout();
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Handle registration
  Future<bool> register(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners();

      final user =
          await _appInitService.authRepository.register(email, password);

      final token = await _appInitService.authRepository.getToken();
      if (token != null) {
        await _appInitService.onLoginSuccess(token);
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }

      throw Exception('Registration succeeded but no token received');
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }
}
