import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../model/auth/auth_response.dart';
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';
import '../model/auth/refresh_token_request.dart';
import '../model/auth/user_info.dart';
import '../utils/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  UserInfo? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserInfo? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  // Initialize auth state from storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _accessToken = await _secureStorage.read(key: 'access_token');
      _refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (_accessToken != null) {
        // Check if token is expired
        if (JwtDecoder.isExpired(_accessToken!)) {
          // Try to refresh token
          if (_refreshToken != null) {
            await _refreshAccessToken();
          } else {
            await _clearAuthData();
          }
        } else {
          // Token is valid, decode user info
          final payload = JwtDecoder.decode(_accessToken!);
          _currentUser = UserInfo.fromJson(payload);
        }
      }
    } catch (e) {
      await _clearAuthData();
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final request = LoginRequest(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      
      final response = await ApiClient.login(request);
      await _saveAuthData(response);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register(String email, String password, String firstName, String lastName) async {
    _setLoading(true);
    _clearError();
    
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      await ApiClient.register(request);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    await _clearAuthData();
    _setLoading(false);
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await ApiClient.forgotPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      await ApiClient.resetPassword(token, newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final request = RefreshTokenRequest(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
      
      final response = await ApiClient.refreshToken(request);
      await _saveAuthData(response);
      return true;
    } catch (e) {
      await _clearAuthData();
      return false;
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _currentUser = response.user;
    
    await _secureStorage.write(key: 'access_token', value: _accessToken);
    await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    
    notifyListeners();
  }

  // Clear authentication data
  Future<void> _clearAuthData() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    
    notifyListeners();
  }

  // Refresh access token (private method)
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) return;
    
    try {
      final request = RefreshTokenRequest(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
      
      final response = await ApiClient.refreshToken(request);
      await _saveAuthData(response);
    } catch (e) {
      await _clearAuthData();
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.roles.contains(role) ?? false;
  }

  // Check if user is admin
  bool get isAdmin => hasRole('Admin');

  // Check if user is organizer
  bool get isOrganizer => hasRole('Organizer');

  // Check if user is scanner
  bool get isScanner => hasRole('Scanner');

  // Check if user is regular user
  bool get isUser => hasRole('User');

  @override
  void dispose() {
    ApiClient.dispose();
    super.dispose();
  }
}
