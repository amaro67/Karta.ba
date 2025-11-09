import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../screens/profile/profile_screen.dart';
import 'admin_sidebar.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/event_management_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/ticket_management_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardContent();
      case 1:
        return const UserManagementScreen();
      case 2:
        return const EventManagementScreen();
      case 3:
        return const OrderManagementScreen();
      case 4:
        return const TicketManagementScreen();
      default:
        return const AdminDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser!;

        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              AdminSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemSelected,
              ),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getTitleForIndex(_selectedIndex),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  // TODO: Show notifications
                                },
                                tooltip: 'Notifications',
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'profile') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const ProfileScreen(),
                                      ),
                                    );
                                  } else if (value == 'logout') {
                                    authProvider.logout();
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: Text(
                                        user.firstName.isNotEmpty
                                            ? user.firstName[0].toUpperCase()
                                            : 'A',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      user.fullName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'profile',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.person, size: 20),
                                        SizedBox(width: 8),
                                        Text('Profile'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.logout, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Logout', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Content Area
                    Expanded(
                      child: _getScreenForIndex(_selectedIndex),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Event Management';
      case 3:
        return 'Order Management';
      case 4:
        return 'Ticket Management';
      default:
        return 'Dashboard';
    }
  }
}

/// Extracted dashboard content (without Scaffold/AppBar)
class AdminDashboardContent extends StatefulWidget {
  const AdminDashboardContent({super.key});

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.refreshDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AdminProvider>(
      builder: (context, authProvider, adminProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${authProvider.currentUser!.fullName}!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administrator Panel',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Stats Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      adminProvider.refreshDashboard();
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              adminProvider.isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.statsError != null
                      ? Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Greška pri učitavanju statistika',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  adminProvider.statsError ?? 'Nepoznata greška',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : adminProvider.dashboardStats == null
                          ? const SizedBox.shrink()
                          : _buildStatsRow(context, adminProvider.dashboardStats),
              const SizedBox(height: 32),

              // Upcoming Events Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to event management (will be handled by parent)
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              adminProvider.isLoadingEvents
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.eventsError != null
                      ? Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Nema dostupnih nadolazećih događaja',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nadolazeći događaji će biti prikazani kada budu dostupni.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : adminProvider.upcomingEvents.isEmpty
                          ? Card(
                              color: Colors.grey.shade100,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nema nadolazećih događaja',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Trenutno nema događaja koji dolaze u bliskoj budućnosti.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: adminProvider.upcomingEvents.length,
                                itemBuilder: (context, index) {
                                  final event = adminProvider.upcomingEvents[index];
                                  return _UpcomingEventCard(event: event);
                                },
                              ),
                            ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0.00 BAM';
    final amount = value is int ? value.toDouble() : value as double;
    return '${amount.toStringAsFixed(2)} BAM';
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic>? stats) {
    // Pokušaj prvo camelCase, pa PascalCase
    final totalRevenue = _getNumericValue(stats, 'totalRevenue') ?? 
                         _getNumericValue(stats, 'TotalRevenue') ?? 0.0;
    final numberOfEvents = _getNumericValue(stats, 'numberOfEvents')?.toInt() ?? 
                          _getNumericValue(stats, 'NumberOfEvents')?.toInt() ?? 0;
    final totalUsers = _getNumericValue(stats, 'totalUsersRegistered')?.toInt() ?? 
                      _getNumericValue(stats, 'TotalUsersRegistered')?.toInt() ?? 0;
    final kartaBaProfit = _getNumericValue(stats, 'kartaBaProfit') ?? 
                         _getNumericValue(stats, 'KartaBaProfit') ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.attach_money,
            title: 'Total Revenue',
            value: _formatCurrency(totalRevenue),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.event,
            title: 'Events',
            value: '$numberOfEvents',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            title: 'Users',
            value: '$totalUsers',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            title: 'karta.ba Profit',
            value: _formatCurrency(kartaBaProfit),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  num? _getNumericValue(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _UpcomingEventCard({required this.event});

  num? _getNumericValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      return parsed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final dateFormat = DateFormat('EEEE - d.M.yyyy - HH:mm');
      // Pokušaj prvo camelCase, pa PascalCase
      final startsAtStr = event['startsAt'] as String? ?? event['StartsAt'] as String?;
      if (startsAtStr == null) {
        return const SizedBox.shrink();
      }
      
      final startsAt = DateTime.parse(startsAtStr);
      final priceFrom = _getNumericValue(event, 'priceFrom') ?? 
                        _getNumericValue(event, 'PriceFrom') ?? 0;
      final currency = event['currency'] as String? ?? 
                      event['Currency'] as String? ?? 'BAM';

      return Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image placeholder
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                  ),
                  child: const Icon(Icons.event, size: 40, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String? ?? event['Title'] as String? ?? 'Event',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(startsAt),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event['location'] as String? ?? event['Location'] as String? ?? ''}, ${event['city'] as String? ?? event['City'] as String? ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From $priceFrom $currency',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading event: $e'),
          ),
        ),
      );
    }
  }
}

