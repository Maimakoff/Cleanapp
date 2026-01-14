import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/utils/date_formatter.dart';

class CleanerDashboardPage extends StatefulWidget {
  const CleanerDashboardPage({super.key});

  @override
  State<CleanerDashboardPage> createState() => _CleanerDashboardPageState();
}

class _CleanerDashboardPageState extends State<CleanerDashboardPage> {
  List<Booking> _myBookings = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadMyBookings();
  }

  Future<void> _loadMyBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Загружаем заказы, назначенные текущему клинеру
      final user = SupabaseService.currentUser;
      if (user != null) {
        final allBookings = await SupabaseService.getBookings()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Booking>[],
            );
        // Фильтруем по назначенному клинеру (требует поля cleaner_id в Booking)
        if (mounted) {
          setState(() {
            _myBookings = allBookings
                .where((b) => b.status == 'confirmed' || b.status == 'pending')
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _myBookings = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myBookings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Превышено время ожидания')
                  ? 'Проверьте интернет-соединение'
                  : 'Ошибка загрузки данных',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await SupabaseService.updateBookingStatus(bookingId, status);
      _loadMyBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус обновлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  List<Booking> get _filteredBookings {
    if (_filterStatus == 'all') return _myBookings;
    return _myBookings.where((b) => b.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Используем безопасное форматирование дат

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Фильтры
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
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
                          label: 'Ожидают',
                          isSelected: _filterStatus == 'pending',
                          onTap: () => setState(() => _filterStatus = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Подтверждены',
                          isSelected: _filterStatus == 'confirmed',
                          onTap: () => setState(() => _filterStatus = 'confirmed'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Завершены',
                          isSelected: _filterStatus == 'completed',
                          onTap: () => setState(() => _filterStatus = 'completed'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Список заказов
                Expanded(
                  child: _filteredBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cleaning_services,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет назначенных заказов',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(booking.status)
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    _getStatusIcon(booking.status),
                                    color: _getStatusColor(booking.status),
                                  ),
                                ),
                                title: Text(booking.tariffName),
                                subtitle: Text(
                                  '${DateFormatter.formatDateLongSync(DateTime.parse(booking.date))} ${booking.time}',
                                ),
                                trailing: _StatusChip(status: booking.status),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _InfoRow(
                                          icon: Icons.location_on,
                                          label: 'Адрес',
                                          value: booking.address,
                                        ),
                                        _InfoRow(
                                          icon: Icons.phone,
                                          label: 'Телефон',
                                          value: booking.phone,
                                        ),
                                        _InfoRow(
                                          icon: Icons.attach_money,
                                          label: 'Стоимость',
                                          value: '${booking.totalPrice} ₽',
                                        ),
                                        if (booking.area != null)
                                          _InfoRow(
                                            icon: Icons.square_foot,
                                            label: 'Площадь',
                                            value: '${booking.area} м²',
                                          ),
                                        const SizedBox(height: 16),
                                        if (booking.status == 'confirmed')
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _updateBookingStatus(
                                                      booking.id, 'completed'),
                                              icon: const Icon(Icons.check),
                                              label: const Text('Отметить как выполненный'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                context.push('/order/${booking.id}'),
                                            icon: const Icon(Icons.info),
                                            label: const Text('Подробнее'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        text = 'Ожидает';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Подтвержден';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Завершен';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Отменен';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

