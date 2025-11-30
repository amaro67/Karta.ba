import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';
import '../providers/auth_provider.dart';

/// Provider for admin dashboard data and state management
class AdminProvider extends ChangeNotifier {
  AuthProvider _authProvider;

  AdminProvider(this._authProvider);

  /// Ensure we always use the latest AuthProvider instance coming from ProxyProvider
  void updateAuthProvider(AuthProvider authProvider) {
    final previousUserId = _authProvider.currentUser?.id;
    final newUserId = authProvider.currentUser?.id;

    _authProvider = authProvider;

    // If user has changed (login/logout), clear cached admin data
    if (previousUserId != newUserId) {
      clear();
    }
  }

  // Dashboard Stats
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Upcoming Events
  List<dynamic> _upcomingEvents = [];
  bool _isLoadingEvents = false;
  String? _eventsError;

  // Users
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  // Getters
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  List<dynamic> get upcomingEvents => _upcomingEvents;
  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventsError => _eventsError;

  List<dynamic> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

  // User Orders
  List<dynamic> _userOrders = [];
  bool _isLoadingUserOrders = false;
  String? _userOrdersError;

  List<dynamic> get userOrders => _userOrders;
  bool get isLoadingUserOrders => _isLoadingUserOrders;
  String? get userOrdersError => _userOrdersError;

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _statsError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      _dashboardStats = await ApiClient.getDashboardStats(token);
      print('🔵 Dashboard stats loaded: $_dashboardStats');
      _statsError = null;
    } catch (e) {
      print('🔴 Error loading dashboard stats: $e');
      _statsError = e.toString();
      _dashboardStats = null;
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load upcoming events
  Future<void> loadUpcomingEvents({int limit = 5}) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _eventsError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingEvents = true;
    _eventsError = null;
    notifyListeners();

    try {
      _upcomingEvents = await ApiClient.getUpcomingEvents(token, limit: limit);
      _eventsError = null;
    } catch (e) {
      _eventsError = e.toString();
      _upcomingEvents = [];
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  // Track ongoing loadUsers call to prevent duplicates
  Future<void>? _loadUsersFuture;

  /// Load all users
  Future<void> loadUsers() async {
    final token = _authProvider.accessToken;
    if (token == null) {
      print('⚠️ AdminProvider: No access token available');
      _usersError = 'Not authenticated';
      notifyListeners();
      return;
    }

    // If already loading, wait for the existing call to complete
    if (_loadUsersFuture != null) {
      print('🔵 AdminProvider: loadUsers() already in progress, waiting for completion...');
      await _loadUsersFuture;
      return;
    }

    print('🔵 AdminProvider: Loading users...');
    _loadUsersFuture = _performLoadUsers(token);
    
    try {
      await _loadUsersFuture;
    } finally {
      _loadUsersFuture = null;
    }
  }

  Future<void> _performLoadUsers(String token) async {
    _isLoadingUsers = true;
    _usersError = null;
    // Don't clear existing users while loading to prevent empty list flash
    notifyListeners();

    try {
      final newUsers = await ApiClient.getAllUsers(token);
      _users = newUsers;
      print('✅ AdminProvider: Loaded ${_users.length} users');
      _usersError = null;
    } catch (e) {
      print('🔴 AdminProvider: Error loading users: $e');
      _usersError = e.toString();
      // Only clear users on error if we don't have existing users
      if (_users.isEmpty) {
        _users = [];
      }
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await Future.wait([
      loadDashboardStats(),
      loadUpcomingEvents(),
    ]);
  }

  // Privremena varijabla za grešku kreiranja korisnika (ne utječe na prikaz tabele)
  String? _createUserError;

  String? get createUserError => _createUserError;

  /// Create new user
  Future<bool> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? roleName,
  }) async {
    final token = _authProvider.accessToken;
    _createUserError = null; // Očisti prethodnu grešku
    
    if (token == null) {
      _createUserError = 'Not authenticated';
      return false;
    }

    try {
      final userData = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (roleName != null && roleName.isNotEmpty) 'roleName': roleName,
      };

      await ApiClient.createUser(token, userData);
      
      // Reload users list
      await loadUsers();
      _createUserError = null;
      return true;
    } catch (e) {
      // Postavi grešku kreiranja korisnika, ali ne mijenjaj _usersError
      // jer to bi sakrilo tabelu ako već postoje korisnici
      String errorMessage = e.toString();
      // Ekstraktuj poruku iz exception stringa ako je potrebno
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.split('Exception:').last.trim();
      }
      _createUserError = errorMessage;
      return false;
    }
  }

  /// Update user
  Future<bool> updateUser({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    bool? emailConfirmed,
  }) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final userData = <String, dynamic>{};
      if (firstName != null && firstName.isNotEmpty) {
        userData['firstName'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        userData['lastName'] = lastName;
      }
      if (email != null && email.isNotEmpty) {
        userData['email'] = email;
      }
      if (emailConfirmed != null) {
        userData['emailConfirmed'] = emailConfirmed;
      }

      await ApiClient.updateUser(token, userId, userData);
      
      // Don't reload users list here - let the calling screen handle it
      // This prevents multiple simultaneous calls and ensures proper refresh timing
      _usersError = null;
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle organizer verification
  Future<bool> setOrganizerVerification(String userId, bool isVerified) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await ApiClient.setOrganizerVerification(token, userId, isVerified);
      _usersError = null;
      await loadUsers();

      if (_authProvider.currentUser?.id == userId) {
        await _authProvider.refreshCurrentUser();
      }
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await ApiClient.deleteUser(token, userId);
      
      // Reload users list
      await loadUsers();
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add role to user
  Future<bool> addUserToRole(String userId, String roleName) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await ApiClient.addUserToRole(token, userId, roleName);
      
      // Reload users list
      await loadUsers();
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove role from user
  Future<bool> removeUserFromRole(String userId, String roleName) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await ApiClient.removeUserFromRole(token, userId, roleName);
      
      // Reload users list
      await loadUsers();
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load user orders
  Future<void> loadUserOrders(String userId) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _userOrdersError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingUserOrders = true;
    _userOrdersError = null;
    notifyListeners();

    try {
      _userOrders = await ApiClient.getUserOrders(token, userId);
      _userOrdersError = null;
    } catch (e) {
      _userOrdersError = e.toString();
      _userOrders = [];
    } finally {
      _isLoadingUserOrders = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _loadUsersFuture = null;
    _dashboardStats = null;
    _upcomingEvents = [];
    _users = [];
    _statsError = null;
    _eventsError = null;
    _usersError = null;
    _createUserError = null;
    _userOrders = [];
    _userOrdersError = null;
    notifyListeners();
  }
}

