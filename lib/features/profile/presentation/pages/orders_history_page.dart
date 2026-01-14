import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/utils/date_formatter.dart';

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({super.key});

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, pending, confirmed, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final bookings = await SupabaseService.getUserBookings(user.id)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Booking>[],
            );
        if (mounted) {
          setState(() {
            _bookings = bookings;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _bookings = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookings = [];
          _isLoading = false;
        });
        // Показываем сообщение об ошибке только если это не просто пустой список
        if (e.toString().contains('Превышено время ожидания')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проверьте интернет-соединение'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  List<Booking> get _filteredBookings {
    if (_filterStatus == 'all') return _bookings;
    return _bookings.where((b) => b.status == _filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Завершен';
      case 'confirmed':
        return 'Подтвержден';
      case 'pending':
        return 'Ожидает';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История заказов'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'У вас пока нет заказов',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Сделайте первый заказ!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter Chips
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Все',
                              isSelected: _filterStatus == 'all',
                              onTap: () => setState(() => _filterStatus = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Ожидает',
                              isSelected: _filterStatus == 'pending',
                              onTap: () => setState(() => _filterStatus = 'pending'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Подтвержден',
                              isSelected: _filterStatus == 'confirmed',
                              onTap: () => setState(() => _filterStatus = 'confirmed'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Завершен',
                              isSelected: _filterStatus == 'completed',
                              onTap: () => setState(() => _filterStatus = 'completed'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Orders List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: _filteredBookings.isEmpty
                            ? Center(
                                child: Text(
                                  'Нет заказов со статусом "${_getStatusText(_filterStatus)}"',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredBookings.length,
                                itemBuilder: (context, index) {
                                  final booking = _filteredBookings[index];
                                  return _OrderCard(
                                    booking: booking,
                                    statusColor: _getStatusColor(booking.status),
                                    statusText: _getStatusText(booking.status),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Booking booking;
  final Color statusColor;
  final String statusText;

  const _OrderCard({
    required this.booking,
    required this.statusColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    // Используем безопасное форматирование дат

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/order/${booking.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.tariffName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatDateLongSync(DateTime.parse(booking.date)),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    booking.time,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.address,
                      style: TextStyle(color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Сумма:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    '${booking.totalPrice.toStringAsFixed(0)} ₸',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
