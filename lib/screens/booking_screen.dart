import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/mobile_layout.dart';
import '../core/services/booking_service.dart';
import '../core/models/booking.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _promoCodeController = TextEditingController();
  
  String _paymentMethod = 'kaspi';
  bool _promoApplied = false;
  bool _saving = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    if (_promoCodeController.text.toLowerCase() == 'welcome') {
      setState(() {
        _promoApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Промокод применён!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный промокод')),
      );
    }
  }

  Future<void> _handleConfirm() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите адрес')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите телефон')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Get booking parameters from URL
      final state = GoRouterState.of(context);
      final uri = state.uri;
      final dateStr = uri.queryParameters['date'] ?? '';
      final time = uri.queryParameters['time'] ?? '';
      final tariffName = uri.queryParameters['name'] ?? 'Услуга';
      final tariffId = uri.queryParameters['tariff'] ?? 
                       uri.queryParameters['tariffId'] ?? 
                       'default-tariff';
      final areaStr = uri.queryParameters['area'] ?? '';

      if (dateStr.isEmpty || time.isEmpty) {
        throw Exception('Дата и время не указаны');
      }

      // Parse date
      final date = DateTime.parse(dateStr);
      
      // Create SelectedDate
      final selectedDate = SelectedDate(date: date, time: time);
      
      // Parse area if provided
      int? area;
      if (areaStr.isNotEmpty) {
        area = int.tryParse(areaStr);
      }

      // Create booking
      await BookingService.createOrder(
        tariffId: tariffId,
        tariffName: tariffName,
        dates: [selectedDate],
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        area: area,
        promoCode: _promoApplied ? _promoCodeController.text.trim().toUpperCase() : null,
      );

      if (mounted) {
        setState(() => _saving = false);
        context.push('/confirmation');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final uri = state.uri;
    final date = uri.queryParameters['date'] ?? '';
    final time = uri.queryParameters['time'] ?? '';
    final tariffName = uri.queryParameters['name'] ?? 'Услуга';
    final total = int.tryParse(uri.queryParameters['total'] ?? '0') ?? 0;
    final area = uri.queryParameters['area'] ?? '';

    int finalTotal = total;
    if (_promoApplied) {
      finalTotal = (total * 0.9).toInt();
    }

    return MobileLayout(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Оформление заказа',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Order Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Детали заказа',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _OrderDetailRow(
                        label: 'Услуга',
                        value: tariffName,
                      ),
                      if (area.isNotEmpty)
                        _OrderDetailRow(
                          label: 'Площадь',
                          value: '$area м²',
                        ),
                      if (date.isNotEmpty)
                        _OrderDetailRow(
                          label: 'Дата',
                          value: DateFormat('d MMMM yyyy', 'ru')
                              .format(DateTime.parse(date)),
                        ),
                      if (time.isNotEmpty)
                        _OrderDetailRow(
                          label: 'Время',
                          value: time,
                        ),
                      const Divider(),
                      _OrderDetailRow(
                        label: 'Стоимость',
                        value: '${total.toStringAsFixed(0)} ₸',
                      ),
                      if (_promoApplied)
                        _OrderDetailRow(
                          label: 'Скидка (WELCOME)',
                          value: '-${(total * 0.1).toInt()} ₸',
                          valueColor: Colors.green,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Contact Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Контактная информация',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          hintText: 'Улица, дом, квартира',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          hintText: '+7 (900) 000-00-00',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Promo Code
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Промокод',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoCodeController,
                              decoration: const InputDecoration(
                                hintText: 'Введите промокод',
                                prefixIcon: Icon(Icons.local_offer),
                              ),
                              enabled: !_promoApplied,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                _promoApplied ? null : _applyPromo,
                            child: const Text('Применить'),
                          ),
                        ],
                      ),
                      if (_promoApplied)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '✓ Промокод применен',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Payment Method
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Способ оплаты',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.payment,
                              label: 'Kaspi',
                              subtitle: 'Kaspi Pay',
                              isSelected: _paymentMethod == 'kaspi',
                              onTap: () => setState(() => _paymentMethod = 'kaspi'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.phone_iphone,
                              label: 'Apple',
                              subtitle: 'Apple Pay',
                              isSelected: _paymentMethod == 'apple',
                              onTap: () => setState(() => _paymentMethod = 'apple'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.credit_card,
                              label: 'Карта',
                              subtitle: 'Visa/MC',
                              isSelected: _paymentMethod == 'card',
                              onTap: () => setState(() => _paymentMethod = 'card'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Total and CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${finalTotal.toStringAsFixed(0)} ₸',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleConfirm,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Подтвердить и оплатить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _OrderDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

