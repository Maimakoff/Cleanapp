import 'package:flutter/material.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/utils/date_formatter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  String _selectedTab = 'orders';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final bookings = await SupabaseService.getBookings()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <Booking>[],
          );
      if (mounted) {
        setState(() {
          _allBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allBookings = [];
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
      _loadData();
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

  @override
  Widget build(BuildContext context) {
    // Используем безопасное форматирование дат

    // Статистика
    final pendingCount = _allBookings.where((b) => b.status == 'pending').length;
    final confirmedCount = _allBookings.where((b) => b.status == 'confirmed').length;
    final completedCount = _allBookings.where((b) => b.status == 'completed').length;
    final totalRevenue = _allBookings
        .where((b) => b.status == 'completed')
        .fold(0, (sum, b) => sum + b.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Статистика
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статистика',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Ожидают',
                              value: pendingCount.toString(),
                              color: Colors.orange,
                              icon: Icons.pending,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Подтверждены',
                              value: confirmedCount.toString(),
                              color: Colors.blue,
                              icon: Icons.check_circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Завершены',
                              value: completedCount.toString(),
                              color: Colors.green,
                              icon: Icons.done_all,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Выручка',
                              value: '$totalRevenue ₽',
                              color: Colors.purple,
                              icon: Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Табы
                Container(
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Заказы',
                          isSelected: _selectedTab == 'orders',
                          onTap: () => setState(() => _selectedTab = 'orders'),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Пользователи',
                          isSelected: _selectedTab == 'users',
                          onTap: () => setState(() => _selectedTab = 'users'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Контент
                Expanded(
                  child: _selectedTab == 'orders'
                      ? _buildOrdersList()
                      : _buildUsersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersList() {
    if (_allBookings.isEmpty) {
      return const Center(child: Text('Нет заказов'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allBookings.length,
      itemBuilder: (context, index) {
        final booking = _allBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(booking.tariffName),
            subtitle: Text('${DateFormatter.formatDateLongSync(DateTime.parse(booking.date))} ${booking.time}'),
            trailing: _StatusChip(status: booking.status),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Адрес', value: booking.address),
                    _InfoRow(label: 'Телефон', value: booking.phone),
                    _InfoRow(label: 'Стоимость', value: '${booking.totalPrice} ₽'),
                    if (booking.area != null)
                      _InfoRow(label: 'Площадь', value: '${booking.area} м²'),
                    const SizedBox(height: 16),
                    const Text(
                      'Изменить статус:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _StatusButton(
                          label: 'Подтвердить',
                          status: 'confirmed',
                          currentStatus: booking.status,
                          onTap: () => _updateBookingStatus(booking.id, 'confirmed'),
                        ),
                        _StatusButton(
                          label: 'Завершить',
                          status: 'completed',
                          currentStatus: booking.status,
                          onTap: () => _updateBookingStatus(booking.id, 'completed'),
                        ),
                        _StatusButton(
                          label: 'Отменить',
                          status: 'cancelled',
                          currentStatus: booking.status,
                          onTap: () => _updateBookingStatus(booking.id, 'cancelled'),
                        ),
                      ],
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

  Widget _buildUsersList() {
    return const Center(
      child: Text('Список пользователей\n(требует реализации в SupabaseService)'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
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
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

class _StatusButton extends StatelessWidget {
  final String label;
  final String status;
  final String currentStatus;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = currentStatus == status || currentStatus == 'completed';
    return ElevatedButton(
      onPressed: isDisabled ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: status == 'confirmed'
            ? Colors.blue
            : status == 'completed'
                ? Colors.green
                : Colors.red,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}

