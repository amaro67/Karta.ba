import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';
import '../providers/auth_provider.dart';

/// Provider for admin dashboard data and state management
class AdminProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  AdminProvider(this._authProvider);

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

  /// Load all users
  Future<void> loadUsers() async {
    final token = _authProvider.accessToken;
    if (token == null) {
      print('⚠️ AdminProvider: No access token available');
      _usersError = 'Not authenticated';
      notifyListeners();
      return;
    }

    print('🔵 AdminProvider: Loading users...');
    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      _users = await ApiClient.getAllUsers(token);
      print('✅ AdminProvider: Loaded ${_users.length} users');
      _usersError = null;
    } catch (e) {
      print('🔴 AdminProvider: Error loading users: $e');
      _usersError = e.toString();
      _users = [];
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

  /// Create new user
  Future<bool> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? roleName,
  }) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _usersError = 'Not authenticated';
      notifyListeners();
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
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear all data
  void clear() {
    _dashboardStats = null;
    _upcomingEvents = [];
    _users = [];
    _statsError = null;
    _eventsError = null;
    _usersError = null;
    notifyListeners();
  }
}

