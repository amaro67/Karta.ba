import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/auth/login_request.dart';
import '../model/auth/register_request.dart';
import '../model/auth/auth_response.dart';
import '../model/auth/refresh_token_request.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:5001';
  static const String apiPrefix = '/api';
  
  static final http.Client _client = http.Client();
  
  // Headers
  static Map<String, String> _getHeaders({String? token, bool includeClientType = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Dodaj X-Client-Type header za karta_desktop
    if (includeClientType) {
      headers['X-Client-Type'] = 'karta_desktop';
    }
    
    return headers;
  }

  // Authentication endpoints
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('🔵 API Request: POST $baseUrl$apiPrefix/Auth/login');
      print('🔵 Request body: ${jsonEncode(request.toJson())}');
      
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/login'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AuthResponse.fromJson(jsonData);
      } else {
        String errorMessage = 'Login failed';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData.toString();
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Login failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('🔴 Login error: $e');
      if (e is SocketException || e.toString().contains('Failed host lookup')) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  static Future<void> register(RegisterRequest request) async {
    try {
      print('🔵 API Request: POST $baseUrl$apiPrefix/Auth/register');
      print('🔵 Request body: ${jsonEncode(request.toJson())}');
      
      final response = await _client.post(
        Uri.parse('$baseUrl$apiPrefix/Auth/register'),
        headers: _getHeaders(includeClientType: true), // Dodaj X-Client-Type header za karta_desktop
        body: jsonEncode(request.toJson()),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful, but no AuthResponse returned
        // User needs to confirm email first
        return;
      } else {
        String errorMessage = 'Registration failed';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
            // Handle validation errors
            if (errorData.containsKey('errors')) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              final errorList = errors.values.expand((e) => e as List).toList();
              errorMessage = errorList.isNotEmpty ? errorList.first.toString() : 'Registration failed';
            } else {
              errorMessage = errorData['message'] ?? errorData.toString();
            }
          } else {
            errorMessage = errorData.toString();
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Registration failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('🔴 Register error: $e');
      if (e is SocketException || e.toString().contains('Failed host lookup')) {
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
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }
        
        final decoded = jsonDecode(response.body);
        if (decoded == null) {
          throw Exception('Null response from server');
        }
        
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is Map) {
          // Convert to Map<String, dynamic>
          return Map<String, dynamic>.from(decoded);
        } else {
          throw Exception('Unexpected response format: expected Map, got ${decoded.runtimeType}');
        }
      } else {
        String errorMessage = 'Request failed with status ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            if (errorData is Map) {
              // Handle validation errors
              if (errorData.containsKey('errors')) {
                final errors = errorData['errors'] as Map<String, dynamic>?;
                if (errors != null && errors.isNotEmpty) {
                  final errorMessages = errors.values
                      .expand((e) => e is List ? e : [e])
                      .map((e) => e.toString())
                      .join(', ');
                  errorMessage = errorMessages;
                } else {
                  errorMessage = errorData['title'] ?? errorData['message'] ?? errorMessage;
                }
              } else {
                errorMessage = errorData['message'] ?? errorData['title'] ?? errorData.toString();
              }
            } else {
              errorMessage = errorData.toString();
            }
          }
        } catch (e) {
          // If JSON parsing fails, use the raw body or default message
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
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

  // ==================== Admin Dashboard Endpoints ====================
  
  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix/Dashboard/stats'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        // Provjeri da li je body prazan
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          // Vrati default vrijednosti ako je body prazan
          return {
            'totalRevenue': 0.0,
            'numberOfEvents': 0,
            'totalUsersRegistered': 0,
            'kartaBaProfit': 0.0,
          };
        }
        
        try {
          final data = jsonDecode(response.body);
          print('🔵 Dashboard stats response: $data');
          if (data is Map<String, dynamic>) {
            return data;
          }
          // Ako nije Map, vrati default vrijednosti
          return {
            'totalRevenue': 0.0,
            'numberOfEvents': 0,
            'totalUsersRegistered': 0,
            'kartaBaProfit': 0.0,
          };
        } catch (e) {
          // Ako jsonDecode ne uspije, vrati default vrijednosti
          print('⚠️ Error parsing dashboard stats JSON: $e');
          return {
            'totalRevenue': 0.0,
            'numberOfEvents': 0,
            'totalUsersRegistered': 0,
            'kartaBaProfit': 0.0,
          };
        }
      } else {
        // Ako status nije 200, pokušaj parsirati error message
        String errorMessage = 'Failed to load dashboard stats (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            print('🔴 Dashboard stats error response (${response.statusCode}): ${response.body}');
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorData['title'] ?? errorMessage;
          }
        } catch (e) {
          print('🔴 Error parsing error response: $e');
          // Ignore JSON parsing errors for error response
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      if (e is FormatException) {
        throw Exception('Invalid response from server. Please try again.');
      }
      rethrow;
    }
  }

  /// Get upcoming events
  static Future<List<dynamic>> getUpcomingEvents(String token, {int limit = 5}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix/Dashboard/upcoming-events?limit=$limit'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        // Provjeri da li je body prazan
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          // Vrati praznu listu ako je body prazan
          return [];
        }
        
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            return List<dynamic>.from(data);
          }
          // Ako nije List, vrati praznu listu
          return [];
        } catch (e) {
          // Ako jsonDecode ne uspije, vrati praznu listu
          print('⚠️ Error parsing upcoming events JSON: $e');
          return [];
        }
      } else {
        // Ako status nije 200, pokušaj parsirati error message
        String errorMessage = 'Failed to load upcoming events (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }
        } catch (_) {
          // Ignore JSON parsing errors for error response
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      if (e is FormatException) {
        throw Exception('Invalid response from server. Please try again.');
      }
      rethrow;
    }
  }

  // ==================== User Management Endpoints ====================
  
  /// Get all users
  static Future<List<dynamic>> getAllUsers(String token) async {
    try {
      print('🔵 API Request: GET $baseUrl$apiPrefix/CoreRole/users');
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix/CoreRole/users'),
        headers: _getHeaders(token: token),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        // Provjeri da li je body prazan
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          print('⚠️ Empty response body');
          return [];
        }
        
        try {
          final data = jsonDecode(response.body);
          if (data is List) {
            print('✅ Parsed ${data.length} users');
            return List<dynamic>.from(data);
          }
          print('⚠️ Response is not a List, returning empty list');
          return [];
        } catch (e) {
          print('🔴 Error parsing users JSON: $e');
          print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          return [];
        }
      } else {
        String errorMessage = 'Failed to load users (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          }
        } catch (_) {
          // Ignore JSON parsing errors for error response
        }
        print('🔴 API Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('🔴 getAllUsers error: $e');
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      if (e is FormatException) {
        throw Exception('Invalid response from server. Please try again.');
      }
      rethrow;
    }
  }

  /// Get user by ID
  static Future<Map<String, dynamic>> getUser(String token, String userId) async {
    return await get('/User/$userId', token: token);
  }

  /// Create new user
  static Future<Map<String, dynamic>> createUser(String token, Map<String, dynamic> userData) async {
    return await post('/User', userData, token: token);
  }

  /// Update user
  static Future<Map<String, dynamic>> updateUser(String token, String userId, Map<String, dynamic> userData) async {
    return await put('/User/$userId', userData, token: token);
  }

  /// Delete user
  static Future<void> deleteUser(String token, String userId) async {
    return await delete('/User/$userId', token: token);
  }

  /// Get user orders
  static Future<List<dynamic>> getUserOrders(String token, String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$apiPrefix/User/$userId/orders'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<dynamic>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load user orders');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Unable to connect to server. Please check your connection.');
      }
      rethrow;
    }
  }

  /// Assign role to user
  static Future<Map<String, dynamic>> assignRole(String token, String userId, String roleName) async {
    return await post('/CoreRole/assign', {
      'userId': userId,
      'roleName': roleName,
    }, token: token);
  }

  // ==================== Event Management Endpoints ====================
  
  /// Get all events (admin view)
  static Future<Map<String, dynamic>> getAllEvents(String token, {
    String? query,
    String? category,
    String? city,
    int page = 1,
    int size = 20,
  }) async {
    final queryParams = <String>[];
    if (query != null && query.isNotEmpty) queryParams.add('query=$query');
    if (category != null && category.isNotEmpty) queryParams.add('category=$category');
    if (city != null && city.isNotEmpty) queryParams.add('city=$city');
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return await get('/Event$queryString', token: token);
  }

  /// Get all events for admin (including archived)
  static Future<Map<String, dynamic>> getAllEventsAdmin(String token, {
    String? query,
    String? category,
    String? city,
    String? status,
    int page = 1,
    int size = 20,
  }) async {
    final queryParams = <String>[];
    if (query != null && query.isNotEmpty) queryParams.add('query=$query');
    if (category != null && category.isNotEmpty) queryParams.add('category=$category');
    if (city != null && city.isNotEmpty) queryParams.add('city=$city');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return await get('/Event/all$queryString', token: token);
  }

  /// Get event by ID
  static Future<Map<String, dynamic>> getEvent(String token, String eventId) async {
    return await get('/Event/$eventId', token: token);
  }

  /// Create event
  static Future<Map<String, dynamic>> createEvent(String token, Map<String, dynamic> eventData) async {
    return await post('/Event', eventData, token: token);
  }

  /// Update event
  static Future<Map<String, dynamic>> updateEvent(String token, String eventId, Map<String, dynamic> eventData) async {
    return await put('/Event/$eventId', eventData, token: token);
  }

  /// Delete event
  static Future<void> deleteEvent(String token, String eventId) async {
    return await delete('/Event/$eventId', token: token);
  }

  // ==================== Order Management Endpoints ====================
  
  /// Get all orders for admin (with filters and pagination)
  static Future<Map<String, dynamic>> getAllOrdersAdmin(String token, {
    String? query,
    String? userId,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int size = 20,
  }) async {
    final queryParams = <String>[];
    if (query != null && query.isNotEmpty) queryParams.add('query=$query');
    if (userId != null && userId.isNotEmpty) queryParams.add('userId=$userId');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    if (from != null) queryParams.add('from=${from.toIso8601String()}');
    if (to != null) queryParams.add('to=${to.toIso8601String()}');
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return await get('/Order/all$queryString', token: token);
  }

  /// Get order by ID (for regular users - requires ownership)
  static Future<Map<String, dynamic>> getOrder(String token, String orderId) async {
    return await get('/Order/$orderId', token: token);
  }

  /// Get order by ID (for admin - no ownership required)
  static Future<Map<String, dynamic>> getOrderAdmin(String token, String orderId) async {
    return await get('/Order/admin/$orderId', token: token);
  }

  // ==================== Ticket Management Endpoints ====================
  
  /// Get all tickets for admin (with filters and pagination)
  static Future<Map<String, dynamic>> getAllTicketsAdmin(String token, {
    String? query,
    String? status,
    String? userId,
    String? eventId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int size = 20,
  }) async {
    final queryParams = <String>[];
    if (query != null && query.isNotEmpty) {
      queryParams.add('query=${Uri.encodeComponent(query)}');
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams.add('userId=${Uri.encodeComponent(userId)}');
    }
    if (eventId != null && eventId.isNotEmpty) {
      queryParams.add('eventId=${Uri.encodeComponent(eventId)}');
    }
    if (from != null) {
      queryParams.add('from=${Uri.encodeComponent(from.toIso8601String())}');
    }
    if (to != null) {
      queryParams.add('to=${Uri.encodeComponent(to.toIso8601String())}');
    }
    queryParams.add('page=$page');
    queryParams.add('size=$size');
    
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return await get('/Ticket/all$queryString', token: token);
  }

  /// Get ticket by ID (for admin - no ownership required)
  static Future<Map<String, dynamic>> getTicketAdmin(String token, String ticketId) async {
    return await get('/Ticket/admin/$ticketId', token: token);
  }

  /// Get ticket by ID (for regular users - requires ownership)
  static Future<Map<String, dynamic>> getTicket(String token, String ticketId) async {
    return await get('/Ticket/$ticketId', token: token);
  }

  // Close the HTTP client
  static void dispose() {
    _client.close();
  }
}
