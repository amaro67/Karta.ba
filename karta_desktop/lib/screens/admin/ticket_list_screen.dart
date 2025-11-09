import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ticket_provider.dart';
import '../../model/order/ticket_dto.dart';
import '../../widgets/loading_widget.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TicketProvider>().loadNextPage();
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    context.read<TicketProvider>().loadTickets(
      query: query.isEmpty ? null : query,
      status: _selectedStatus,
      from: _fromDate,
      to: _toDate,
    );
  }

  void _handleFilter() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        status: _selectedStatus,
        fromDate: _fromDate,
        toDate: _toDate,
        onApply: (status, from, to) {
          setState(() {
            _selectedStatus = status;
            _fromDate = from;
            _toDate = to;
          });
          context.read<TicketProvider>().loadTickets(
            query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            status: status,
            from: from,
            to: to,
          );
        },
      ),
    );
  }

  void _handleTicketTap(TicketDto ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _handleFilter,
            tooltip: 'Filter Tickets',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TicketProvider>().refreshTickets(),
            tooltip: 'Refresh Tickets',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Ticket Code...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _handleSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
          ),
          // Tickets list
          Expanded(
            child: Consumer<TicketProvider>(
              builder: (context, ticketProvider, child) {
                if (ticketProvider.isLoading && ticketProvider.tickets == null) {
                  return const LoadingWidget(message: 'Loading tickets...');
                }

                if (ticketProvider.error != null && ticketProvider.tickets == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${ticketProvider.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ticketProvider.loadTickets(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tickets = ticketProvider.tickets?.items ?? [];
                if (tickets.isEmpty) {
                  return const Center(
                    child: Text('No tickets found.'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: tickets.length + (ticketProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tickets.length) {
                      return const LoadingWidget(message: 'Loading more tickets...');
                    }
                    final ticket = tickets[index];
                    return _TicketCard(
                      ticket: ticket,
                      onTap: () => _handleTicketTap(ticket),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketDto ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (ticket.status.toLowerCase()) {
      case 'issued':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'used':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketCode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${ticket.status}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Issued: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.issuedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (ticket.usedAt != null)
                      Text(
                        'Used: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.usedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(String?, DateTime?, DateTime?) onApply;

  const _FilterDialog({
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedStatus;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.status;
    _selectedFromDate = widget.fromDate;
    _selectedToDate = widget.toDate;
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isFromDate ? _selectedFromDate : _selectedToDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = picked;
        } else {
          _selectedToDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Tickets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Issued', child: Text('Issued')),
                DropdownMenuItem(value: 'Used', child: Text('Used')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _selectedFromDate == null
                    ? 'From Date'
                    : 'From: ${DateFormat('dd/MM/yyyy').format(_selectedFromDate!)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                _selectedToDate == null
                    ? 'To Date'
                    : 'To: ${DateFormat('dd/MM/yyyy').format(_selectedToDate!)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedFromDate = null;
                      _selectedToDate = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedStatus, _selectedFromDate, _selectedToDate);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
