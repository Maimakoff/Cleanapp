import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/core/utils/date_formatter.dart';
import 'package:cleanapp/core/services/booking_service.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/utils/validators.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _areaController = TextEditingController();
  
  String _paymentMethod = 'kaspi';
  bool _promoApplied = false;
  bool _saving = false;
  DateTime? _lastSubmitTime; // Race condition protection

  @override
  void initState() {
    super.initState();
    // Добавляем слушатель для автоматического пересчёта цены
    _areaController.addListener(_onAreaChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем площадь из URL, если есть (только один раз)
    if (_areaController.text.isEmpty) {
      final state = GoRouterState.of(context);
      final uri = state.uri;
      final areaFromUrl = uri.queryParameters['area'] ?? '';
      if (areaFromUrl.isNotEmpty) {
        _areaController.text = areaFromUrl;
      }
    }
  }

  void _onAreaChanged() {
    // Пересчитываем цену при изменении площади
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _promoCodeController.dispose();
    _areaController.removeListener(_onAreaChanged);
    _areaController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    if (_promoCodeController.text.toLowerCase() == 'welcome') {
      setState(() {
        _promoApplied = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Промокод применён!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный промокод')),
        );
      }
    }
  }

  Future<void> _handleConfirm() async {
    // Double-submit protection
    if (_saving) return;
    
    // Race condition protection: prevent multiple rapid submissions
    final now = DateTime.now();
    if (_lastSubmitTime != null && 
        now.difference(_lastSubmitTime!).inMilliseconds < 2000) {
      return; // Ignore if submitted less than 2 seconds ago
    }
    _lastSubmitTime = now;
    
    // Валидация адреса
    final addressError = Validators.validateAddress(_addressController.text);
    if (addressError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(addressError)),
        );
      }
      return;
    }

    // Валидация телефона
    final phoneError = Validators.validatePhone(_phoneController.text);
    if (phoneError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(phoneError)),
        );
      }
      return;
    }

    // Валидация площади
    final areaError = Validators.validateArea(_areaController.text);
    if (areaError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(areaError)),
        );
      }
      return;
    }

    if (!mounted) return;
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

      if (dateStr.isEmpty || time.isEmpty) {
        throw Exception('Дата и время не указаны');
      }

      // Validate and parse date
      if (!Validators.isValidDateString(dateStr)) {
        throw Exception('Некорректная дата');
      }
      
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        throw Exception('Некорректная дата');
      }
      
      // Validate time
      if (!Validators.isValidTimeString(time)) {
        throw Exception('Некорректное время');
      }
      
      // Create SelectedDate
      final selectedDate = SelectedDate(date: date, time: time);
      
      // Parse area from input field (обязательное поле)
      final areaText = _areaController.text.trim();
      final area = int.tryParse(areaText);
      if (area == null || area <= 0) {
        throw Exception('Некорректная площадь');
      }

      // Calculate final price using new calculator logic
      final basePrice = _calculateTotalPrice(tariffId, area);
      final finalPrice = _promoApplied 
          ? (basePrice * 0.9).round() 
          : basePrice;

      // Create booking with timeout
      await BookingService.createOrder(
        tariffId: tariffId,
        tariffName: tariffName,
        dates: [selectedDate],
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        area: area,
        promoCode: _promoApplied ? _promoCodeController.text.trim().toUpperCase() : null,
        paymentMethod: _paymentMethod,
        totalPrice: finalPrice,
      );

      if (mounted) {
        setState(() => _saving = false);
        context.push('/confirmation');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        
        String errorMessage = e.toString();
        
        // Обработка специфичных ошибок
        if (errorMessage.contains('Превышено время ожидания') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('TimeoutException')) {
          errorMessage = 'Превышено время ожидания. Проверьте интернет-соединение и попробуйте снова';
        } else if (errorMessage.contains('Ошибка сети') ||
            errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('SocketException')) {
          errorMessage = 'Ошибка сети. Проверьте интернет-соединение';
        } else if (errorMessage.contains('Not authenticated') ||
            errorMessage.contains('unauthorized')) {
          errorMessage = 'Сессия истекла. Пожалуйста, войдите в аккаунт снова';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.replaceAll('Exception: ', '').replaceAll('TimeoutException: ', ''),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Калькулятор стоимости уборки
  /// 
  /// Правила расчёта:
  /// - Минимальная цена: 20 000 тг (даже для площади ≤ 50 м²)
  /// - Базовая площадь: 50 м² (включена в стартовую цену)
  /// - Тариф "Старт": 400 тг/м² за площадь свыше 50 м²
  /// - Остальные тарифы (кроме мебели): 350 тг/м² за площадь свыше 50 м²
  /// - Тариф "Мебель": фиксированные цены (старая логика)
  int _calculateTotalPrice(String tariffId, int area) {
    // Для тарифа "Мебель" используем старую логику (фиксированные цены)
    if (tariffId == 'furniture') {
      return 5000; // Минимальная цена для мебели
    }
    
    // Минимальная (стартовая) цена всегда 20 000 тг
    const int basePrice = 20000;
    const int baseArea = 50; // Базовая площадь, включённая в стартовую цену
    
    // Если площадь ≤ 50 м², возвращаем минимальную цену
    if (area <= baseArea) {
      return basePrice;
    }
    
    // Определяем цену за м² в зависимости от тарифа
    int pricePerSqm;
    if (tariffId == 'start') {
      pricePerSqm = 400; // Тариф "Старт"
    } else {
      // Все остальные тарифы (comfort, premium, lux, after-renovation)
      pricePerSqm = 350;
    }
    
    // Рассчитываем итоговую цену: базовая цена + (площадь - базовая площадь) × цена за м²
    final additionalArea = area - baseArea;
    final totalPrice = basePrice + (additionalArea * pricePerSqm);
    
    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final uri = state.uri;
    final date = uri.queryParameters['date'] ?? '';
    final time = uri.queryParameters['time'] ?? '';
    final tariffName = uri.queryParameters['name'] ?? 'Услуга';
    final tariffId = uri.queryParameters['tariff'] ?? 
                     uri.queryParameters['tariffId'] ?? 
                     'default-tariff';
    
    // Получаем площадь из поля ввода (или из URL, если поле пустое)
    final areaText = _areaController.text.trim();
    final areaFromInput = areaText.isNotEmpty ? int.tryParse(areaText) : null;
    final areaFromUrl = uri.queryParameters['area'] ?? '';
    final area = areaFromInput ?? (areaFromUrl.isNotEmpty ? int.tryParse(areaFromUrl) : null) ?? 50;

    // Пересчитываем цену на основе площади и тарифа
    final baseTotal = _calculateTotalPrice(tariffId, area);
    
    int finalTotal = baseTotal;
    if (_promoApplied) {
      finalTotal = (baseTotal * 0.9).round();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      // Показываем площадь (обязательное поле)
                      _OrderDetailRow(
                        label: 'Площадь',
                        value: '$area м²',
                      ),
                      if (date.isNotEmpty)
                        FutureBuilder<String>(
                          future: DateFormatter.formatDateLong(DateTime.parse(date)),
                          builder: (context, snapshot) {
                            final dateText = snapshot.hasData 
                                ? snapshot.data! 
                                : DateFormatter.formatDateLongSync(DateTime.parse(date));
                            return _OrderDetailRow(
                              label: 'Дата',
                              value: dateText,
                            );
                          },
                        ),
                      if (time.isNotEmpty)
                        _OrderDetailRow(
                          label: 'Время',
                          value: time,
                        ),
                      const Divider(),
                      _OrderDetailRow(
                        label: 'Стоимость',
                        value: '${baseTotal.toStringAsFixed(0)} ₸',
                      ),
                      if (_promoApplied)
                        _OrderDetailRow(
                          label: 'Скидка (WELCOME)',
                          value: '-${(baseTotal * 0.1).round()} ₸',
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
                  child: Form(
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
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Адрес',
                            hintText: 'Улица, дом, квартира',
                          ),
                          maxLength: 500,
                          validator: Validators.validateAddress,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Телефон',
                            hintText: '+7 (900) 000-00-00',
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 20,
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(
                            labelText: 'Площадь',
                            hintText: 'Введите площадь в м²',
                            helperText: 'Обязательное поле',
                            prefixIcon: Icon(Icons.square_foot),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          validator: Validators.validateArea,
                          onChanged: (_) {
                            // Автоматический пересчёт цены при изменении площади
                            setState(() {});
                          },
                        ),
                      ],
                    ),
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
                            onPressed: (_promoApplied || _saving) 
                                ? null 
                                : _applyPromo,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.payment,
                              label: 'Kaspi',
                              subtitle: 'Kaspi Pay',
                              isSelected: _paymentMethod == 'kaspi',
                              onTap: _saving 
                                  ? () {} 
                                  : () => setState(() => _paymentMethod = 'kaspi'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.phone_iphone,
                              label: 'Apple',
                              subtitle: 'Apple Pay',
                              isSelected: _paymentMethod == 'apple',
                              onTap: _saving 
                                  ? () {} 
                                  : () => setState(() => _paymentMethod = 'apple'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.credit_card,
                              label: 'Карта',
                              subtitle: 'Visa/MC',
                              isSelected: _paymentMethod == 'card',
                              onTap: _saving 
                                  ? () {} 
                                  : () => setState(() => _paymentMethod = 'card'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.money,
                              label: 'Наличные',
                              subtitle: 'При получении',
                              isSelected: _paymentMethod == 'cash',
                              onTap: _saving 
                                  ? () {} 
                                  : () => setState(() => _paymentMethod = 'cash'),
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
                      onPressed: (_saving || !mounted) ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _paymentMethod == 'cash' 
                                  ? 'Подтвердить заказ'
                                  : 'Подтвердить и оплатить',
                              style: const TextStyle(
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
