import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';
import '../model/auth/auth_response.dart';
import '../model/auth/refresh_token_request.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api';
  
  static final http.Client _client = http.Client();
  
  // Headers
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Authentication endpoints
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/login'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<void> register(RegisterRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/register'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        // Registration successful, but no AuthResponse returned
        // User needs to confirm email first
        return;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<AuthResponse> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/refresh-token'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Token refresh failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<void> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Password reset request failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic GET request with authentication
  static Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic POST request with authentication
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic PUT request with authentication
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic DELETE request with authentication
  static Future<void> delete(String endpoint, {String? token}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$apiPrefix$endpoint'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Delete failed');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  // Close the HTTP client
  static void dispose() {
    _client.close();
  }
}
