import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karta_shared/karta_shared.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/ticket_card.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<TicketDto> _tickets = [];
  bool _isLoading = true;
  String? _error;
  
  // Map to store ticketId -> eventId
  final Map<String, String> _ticketToEventMap = {};
  // Map to store eventId -> EventDto
  final Map<String, EventDto> _eventMap = {};
  // Map to store ticketId -> OrderItemDto
  final Map<String, OrderItemDto> _ticketToOrderItemMap = {};

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if we haven't loaded yet (first time) or if explicitly needed
    // Don't refresh every time we come back from detail screen
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadTickets();
        }
      });
    }
  }

  Future<void> _loadTickets({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Fetch tickets
      final ticketsResponse = await ApiClient.getList('/Ticket/my-tickets', token: token);
      final allTickets = ticketsResponse
          .map((json) => TicketDto.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fetch orders to get event information
      final ordersResponse = await ApiClient.getMyOrders(token);
      final orders = ordersResponse
          .map((json) => OrderDto.fromJson(json as Map<String, dynamic>))
          .toList();

      // Create maps of ticketId -> eventId and ticketId -> orderItem
      _ticketToEventMap.clear();
      _ticketToOrderItemMap.clear();
      for (final order in orders) {
        for (final item in order.items) {
          for (final ticket in item.tickets) {
            _ticketToEventMap[ticket.id] = item.eventId;
            _ticketToOrderItemMap[ticket.id] = item;
          }
        }
      }

      // Get unique event IDs
      final eventIds = _ticketToEventMap.values.toSet().toList();

      // Fetch events for those eventIds
      _eventMap.clear();
      final eventProvider = context.read<EventProvider>();
      for (final eventId in eventIds) {
        try {
          await eventProvider.loadEvent(eventId);
          if (eventProvider.currentEvent != null) {
            _eventMap[eventId] = eventProvider.currentEvent!;
          }
        } catch (e) {
          // If event fetch fails, skip it
          print('Failed to load event $eventId: $e');
        }
      }

      // Filter tickets to only include those with valid event data
      // Show all tickets (past and future events)
      final validTickets = allTickets.where((ticket) {
        final eventId = _ticketToEventMap[ticket.id];
        if (eventId == null) return false;
        final event = _eventMap[eventId];
        return event != null;
      }).toList();

      setState(() {
        _tickets = validTickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('karta.ba'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _showMenu(context);
            },
          ),
        ],
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(UserInfo? user) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading tickets',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTickets,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No tickets yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Browse events and purchase your first ticket',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: const Text('Browse Events'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Text(
              "${user.firstName}'s tickets",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
          ],
          
          ..._tickets.map((ticket) {
            final eventId = _ticketToEventMap[ticket.id];
            final event = eventId != null ? _eventMap[eventId] : null;
            final orderItem = _ticketToOrderItemMap[ticket.id];
            
            return TicketCard(
              ticket: ticket,
              event: event,
              orderItem: orderItem,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.ticketDetail,
                  arguments: {
                    'ticket': ticket,
                    'event': event,
                    'orderItem': orderItem,
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Divider(height: 32),
              ],
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('My Events'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.myEvents);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
