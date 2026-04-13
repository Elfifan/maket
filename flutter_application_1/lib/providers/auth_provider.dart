import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> initialize() async {
    await _supabaseService.initialize();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      print('Login error in provider: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.register(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print('Registration error in provider: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<bool> refreshCurrentUser() async {
    if (_currentUser?.id == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _supabaseService.getUserById(_currentUser!.id!);
      _isLoading = false;
      if (updatedUser == null) {
        return false;
      }
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error refreshing user in provider: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}