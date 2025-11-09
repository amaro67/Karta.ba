import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../model/order/order_item_dto.dart';
import '../../model/order/ticket_dto.dart';
import '../../model/event/price_tier_dto.dart';
import '../../widgets/loading_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoadingOrder) {
            return const LoadingWidget(message: 'Loading order...');
          }

          if (orderProvider.orderError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${orderProvider.orderError}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => orderProvider.loadOrder(widget.orderId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = orderProvider.currentOrder;
          if (order == null) {
            return const Center(
              child: Text('Order not found.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            _StatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // User information section
                        Builder(
                          builder: (context) {
                            final userDetails = orderProvider.userDetails;
                            final userDetailsError = orderProvider.userDetailsError;
                            final isLoadingUserDetails = orderProvider.isLoadingUserDetails;
                            
                            // Check if user was not found (404 or similar)
                            final userNotFound = userDetailsError != null && 
                                (userDetailsError.contains('404') || 
                                 userDetailsError.contains('not found') ||
                                 userDetailsError.contains('Korisnik nije pronađen'));
                            
                            // Show user information (from userDetails or fallback to order)
                            final firstName = userDetails?.firstName ?? order.userFirstName ?? '';
                            final lastName = userDetails?.lastName ?? order.userLastName ?? '';
                            final email = userDetails?.email ?? order.userEmail ?? '';
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (userNotFound) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'User no longer exists in database',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.orange.shade700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                _InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'First Name',
                                  value: firstName.isEmpty ? (userNotFound ? 'N/A' : '-') : firstName,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Last Name',
                                  value: lastName.isEmpty ? (userNotFound ? 'N/A' : '-') : lastName,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: email.isEmpty ? (userNotFound ? 'N/A' : '-') : email,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.info_outline,
                                  label: 'User ID',
                                  value: order.userId,
                                ),
                                if (isLoadingUserDetails && userDetails == null && !userNotFound) ...[
                                  const SizedBox(height: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 28),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Loading user details...'),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Created At',
                          value: _formatDateTime(order.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.attach_money,
                          label: 'Total Amount',
                          value: '${order.totalAmount.toStringAsFixed(2)} ${order.currency}',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.confirmation_number,
                          label: 'Total Tickets',
                          value: '${order.totalTickets}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => _OrderItemCard(item: item)),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${order.totalAmount.toStringAsFixed(2)} ${order.currency}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'paid':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'refunded':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItemDto item;

  const _OrderItemCard({required this.item});

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final eventDetails = orderProvider.getEventDetails(item.eventId);
        final isLoadingEvent = orderProvider.isLoadingEvent(item.eventId);
        
        // Find price tier from event details
        PriceTierDto? priceTier;
        if (eventDetails != null) {
          try {
            priceTier = eventDetails.priceTiers.firstWhere(
              (tier) => tier.id == item.priceTierId,
            );
          } catch (e) {
            // Price tier not found in event
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              eventDetails != null 
                ? eventDetails.title 
                : 'Event: ${item.eventId.substring(0, 8)}...',
            ),
            subtitle: Text('Quantity: ${item.qty} × ${item.unitPrice.toStringAsFixed(2)}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Information Section
                    Text(
                      'Event Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ItemInfoRow(label: 'Event ID', value: item.eventId),
                    if (eventDetails != null) ...[
                      _ItemInfoRow(label: 'Title', value: eventDetails.title),
                      if (eventDetails.description != null && eventDetails.description!.isNotEmpty)
                        _ItemInfoRow(
                          label: 'Description',
                          value: eventDetails.description!,
                        ),
                      _ItemInfoRow(
                        label: 'Starts At',
                        value: _formatDateTime(eventDetails.startsAt),
                      ),
                      _ItemInfoRow(label: 'Status', value: eventDetails.status),
                    ] else if (isLoadingEvent) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading event details...'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Price Tier Information Section
                    Text(
                      'Price Tier Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ItemInfoRow(label: 'Price Tier ID', value: item.priceTierId),
                    if (priceTier != null) ...[
                      _ItemInfoRow(label: 'Name', value: priceTier.name),
                      _ItemInfoRow(
                        label: 'Price',
                        value: '${priceTier.price.toStringAsFixed(2)} ${priceTier.currency}',
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Order Item Information
                    Text(
                      'Order Item Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ItemInfoRow(label: 'Quantity', value: item.qty.toString()),
                    _ItemInfoRow(label: 'Unit Price', value: item.unitPrice.toStringAsFixed(2)),
                    _ItemInfoRow(
                      label: 'Subtotal',
                      value: (item.qty * item.unitPrice).toStringAsFixed(2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tickets (${item.tickets.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...item.tickets.map((ticket) => _TicketCard(ticket: ticket)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ItemInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketDto ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.ticketCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    'Status: ${ticket.status}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (ticket.usedAt != null)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

