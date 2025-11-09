import 'package:flutter/foundation.dart';
import '../model/order/order_dto.dart';
import '../model/event/paged_result.dart';
import '../model/event/event_dto.dart';
import '../model/user/user_detail_response.dart';
import '../utils/api_client.dart';
import '../providers/auth_provider.dart';

class OrderProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  OrderProvider(this._authProvider);

  // Orders list
  PagedResult<OrderDto>? _orders;
  bool _isLoading = false;
  String? _error;

  // Current order (for detail view)
  OrderDto? _currentOrder;
  bool _isLoadingOrder = false;
  String? _orderError;

  // User details for current order
  UserDetailResponse? _userDetails;
  bool _isLoadingUserDetails = false;
  String? _userDetailsError;

  // Event details for current order items (keyed by eventId)
  final Map<String, EventDto> _eventDetails = {};
  final Set<String> _loadingEventIds = {};

  // Filters
  String? _searchQuery;
  String? _userId;
  String? _status;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _currentPage = 1;
  int _pageSize = 20;

  // Getters
  PagedResult<OrderDto>? get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderDto? get currentOrder => _currentOrder;
  bool get isLoadingOrder => _isLoadingOrder;
  String? get orderError => _orderError;

  UserDetailResponse? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;
  String? get userDetailsError => _userDetailsError;

  EventDto? getEventDetails(String eventId) => _eventDetails[eventId];
  bool isLoadingEvent(String eventId) => _loadingEventIds.contains(eventId);

  String? get searchQuery => _searchQuery;
  String? get userId => _userId;
  String? get status => _status;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  /// Load orders with filters
  Future<void> loadOrders({
    String? query,
    String? userId,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    bool append = false,
  }) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    if (!append) {
      _currentPage = page;
    }
    _searchQuery = query;
    _userId = userId;
    _status = status;
    _fromDate = from;
    _toDate = to;
    notifyListeners();

    try {
      final response = await ApiClient.getAllOrdersAdmin(
        token,
        query: query,
        userId: userId,
        status: status,
        from: from,
        to: to,
        page: page,
        size: _pageSize,
      );

      final pagedResult = PagedResult<OrderDto>.fromJson(
        response,
        (json) => OrderDto.fromJson(json as Map<String, dynamic>),
      );

      if (append && _orders != null) {
        // Append to existing list
        _orders = PagedResult<OrderDto>(
          items: [..._orders!.items, ...pagedResult.items],
          page: pagedResult.page,
          size: pagedResult.size,
          total: pagedResult.total,
        );
      } else {
        _orders = pagedResult;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      if (!append) {
        _orders = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load order by ID (for admin)
  Future<void> loadOrder(String orderId, {bool useAdminEndpoint = true}) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _orderError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingOrder = true;
    _orderError = null;
    notifyListeners();

    try {
      final response = useAdminEndpoint
          ? await ApiClient.getOrderAdmin(token, orderId)
          : await ApiClient.getOrder(token, orderId);
      _currentOrder = OrderDto.fromJson(response);
      _orderError = null;

      // Load user details if order has userId
      if (_currentOrder != null && _currentOrder!.userId.isNotEmpty) {
        await loadUserDetails(_currentOrder!.userId);
      }

      // Load event details for all order items
      if (_currentOrder != null) {
        final eventIds = _currentOrder!.items.map((item) => item.eventId).toSet();
        for (final eventId in eventIds) {
          await loadEventDetails(eventId);
        }
      }
    } catch (e) {
      _orderError = e.toString();
      _currentOrder = null;
    } finally {
      _isLoadingOrder = false;
      notifyListeners();
    }
  }

  /// Load user details by user ID
  Future<void> loadUserDetails(String userId) async {
    final token = _authProvider.accessToken;
    if (token == null) {
      _userDetailsError = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoadingUserDetails = true;
    _userDetailsError = null;
    notifyListeners();

    try {
      final response = await ApiClient.getUser(token, userId);
      _userDetails = UserDetailResponse.fromJson(response);
      _userDetailsError = null;
    } catch (e) {
      _userDetailsError = e.toString();
      _userDetails = null;
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }

  /// Load event details by event ID
  Future<void> loadEventDetails(String eventId) async {
    final token = _authProvider.accessToken;
    if (token == null) return;

    // Skip if already loading or already loaded
    if (_loadingEventIds.contains(eventId) || _eventDetails.containsKey(eventId)) {
      return;
    }

    _loadingEventIds.add(eventId);
    notifyListeners();

    try {
      final response = await ApiClient.getEvent(token, eventId);
      final event = EventDto.fromJson(response);
      _eventDetails[eventId] = event;
    } catch (e) {
      print('Error loading event details: $e');
      // Don't store error, just skip
    } finally {
      _loadingEventIds.remove(eventId);
      notifyListeners();
    }
  }

  /// Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    _orderError = null;
    _userDetails = null;
    _userDetailsError = null;
    _eventDetails.clear();
    _loadingEventIds.clear();
    notifyListeners();
  }

  /// Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders(
      query: _searchQuery,
      userId: _userId,
      status: _status,
      from: _fromDate,
      to: _toDate,
      page: _currentPage,
    );
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_orders != null && _orders!.hasNextPage && !_isLoading) {
      await loadOrders(
        query: _searchQuery,
        userId: _userId,
        status: _status,
        from: _fromDate,
        to: _toDate,
        page: _currentPage + 1,
        append: true,
      );
    }
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = null;
    _userId = null;
    _status = null;
    _fromDate = null;
    _toDate = null;
    _currentPage = 1;
    notifyListeners();
  }
}

