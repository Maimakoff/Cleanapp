import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_layout.dart';
import '../core/services/booking_service.dart';
import '../core/models/booking.dart';
import '../core/utils/date_formatter.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _paymentMethod = 'kaspi';
  bool _promoApplied = false;
  bool _saving = false;
  int _area = 0; // Площадь в м²
  
  // Константы для расчета цены
  static const int minPrice = 20000; // Минимальная цена в тенге
  static const int pricePerSquareMeter = 500; // Цена за м² после 50 м²
  static const int thresholdArea = 50; // Порог площади в м²

  @override
  void initState() {
    super.initState();
    // Инициализируем площадь из URL, если передана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = GoRouterState.of(context);
        final uri = state.uri;
        final tariffId = uri.queryParameters['tariff'] ?? 
                         uri.queryParameters['tariffId'] ?? 
                         'default-tariff';
        final areaStr = uri.queryParameters['area'] ?? '';
        
        if (areaStr.isNotEmpty) {
          final areaFromUrl = int.tryParse(areaStr);
          if (areaFromUrl != null && areaFromUrl > 0) {
            setState(() {
              _area = areaFromUrl;
              // Заполняем поле для всех тарифов, кроме мебели
              if (tariffId != 'furniture') {
                _areaController.text = areaFromUrl.toString();
              }
            });
          } else if (tariffId != 'furniture') {
            _areaController.text = _area.toString();
          }
        } else if (tariffId != 'furniture') {
          _areaController.text = _area.toString();
        }
      }
    });
    
    // Слушаем изменения в поле площади
    _areaController.addListener(() {
      final areaValue = int.tryParse(_areaController.text);
      if (areaValue != null && areaValue > 0) {
        setState(() {
          _area = areaValue;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _promoCodeController.dispose();
    _areaController.dispose();
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
    if (_saving) return; // Предотвращаем повторные запросы
    
    if (_addressController.text.trim().isEmpty) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите адрес')),
      );
      }
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите телефон')),
      );
      }
      return;
    }

    // Проверяем, что площадь указана (только для тарифов, где нужна площадь)
    final state = GoRouterState.of(context);
    final uri = state.uri;
    final tariffId = uri.queryParameters['tariff'] ?? 
                     uri.queryParameters['tariffId'] ?? 
                     'default-tariff';
    
    // Проверяем площадь для всех тарифов, кроме мебели
    if (tariffId != 'furniture') {
      // Валидируем форму
      if (!_formKey.currentState!.validate()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пожалуйста, укажите корректную площадь'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Проверяем, что площадь введена
      if (_areaController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пожалуйста, укажите площадь квартиры или дома'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final areaValue = int.tryParse(_areaController.text);
      if (areaValue == null || areaValue < 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Минимальное значение площади: 1 м²'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() {
        _area = areaValue;
      });
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

      // Parse date
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        throw Exception('Некорректная дата');
      }
      
      // Create SelectedDate
      final selectedDate = SelectedDate(date: date, time: time);
      
      // Используем площадь из поля ввода
      int? area;
      if (tariffId != 'furniture') {
        area = _area;
      }

      // Calculate final price (используем новую логику расчета)
      final basePrice = _calculateTotalPrice(tariffId, _area.toString());
      final finalPrice = _promoApplied 
          ? ((basePrice * 0.9).round() < minPrice ? minPrice : (basePrice * 0.9).round())
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
        final errorLower = errorMessage.toLowerCase();
        
        // Обработка специфичных ошибок
        if (errorLower.contains('превышено время ожидания') ||
            errorLower.contains('timeout') ||
            errorLower.contains('timeoutexception')) {
          errorMessage = 'Превышено время ожидания. Проверьте интернет-соединение и попробуйте снова';
        } else if (errorLower.contains('ошибка сети') ||
            errorLower.contains('network') ||
            errorLower.contains('connection') ||
            errorLower.contains('socketexception') ||
            errorLower.contains('failed host lookup')) {
          errorMessage = 'Ошибка сети. Проверьте интернет-соединение и попробуйте снова';
        } else if (errorLower.contains('not authenticated') ||
            errorLower.contains('unauthorized') ||
            errorLower.contains('сессия истекла')) {
          errorMessage = 'Сессия истекла. Пожалуйста, войдите в аккаунт снова';
        } else if (errorLower.contains('api url не настроен') ||
            errorLower.contains('api url') ||
            errorLower.contains('конфигурация')) {
          errorMessage = 'Ошибка конфигурации. Обратитесь в поддержку';
        } else if (errorLower.contains('ошибка сервера') ||
            errorLower.contains('500') ||
            errorLower.contains('502') ||
            errorLower.contains('503')) {
          errorMessage = 'Ошибка сервера. Попробуйте позже или обратитесь в поддержку';
        } else if (errorLower.contains('400') ||
            errorLower.contains('404') ||
            errorLower.contains('некорректный запрос')) {
          errorMessage = 'Некорректные данные. Проверьте введенную информацию и попробуйте снова';
        } else if (errorLower.contains('пустой ответ') ||
            errorLower.contains('empty response')) {
          errorMessage = 'Сервер не ответил. Проверьте интернет-соединение и попробуйте снова';
        } else {
          // Убираем технические детали из сообщения для пользователя
          errorMessage = errorMessage
              .replaceAll('Exception: ', '')
              .replaceAll('TimeoutException: ', '')
              .replaceAll('SocketException: ', '')
              .trim();
          
          // Если сообщение слишком техническое, показываем общее
          if (errorMessage.contains('FormatException') ||
              errorMessage.contains('TypeError') ||
              errorMessage.length > 100) {
            errorMessage = 'Ошибка при создании заказа. Попробуйте снова или обратитесь в поддержку';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  String _getFrequencyLabel(String frequency) {
    const frequencyMap = {
      'daily': 'Ежедневно',
      'weekly': 'Еженедельно',
      'biweekly': '2 раза в неделю',
      'monthly': 'Раз в месяц',
    };
    return frequencyMap[frequency] ?? frequency;
  }

  /// Расчет цены согласно требованиям:
  /// - Если площадь ≤ 50 м² → цена всегда 20,000 ₸
  /// - Если площадь > 50 м² → цена = 20,000 + (площадь - 50) * pricePerSquareMeter
  int _calculatePrice(int area) {
    if (area <= thresholdArea) {
      return minPrice;
    }
    
    // Цена = минимум + (площадь - порог) * цена за м²
    return minPrice + (area - thresholdArea) * pricePerSquareMeter;
  }

  int _calculateTotalPrice(String tariffId, String areaStr) {
    // Для мебели фиксированная цена 5000
    if (tariffId == 'furniture') {
      return 5000;
    }
    
    // Для корпоративного тарифа используем цену из URL
    if (tariffId == 'corporate') {
      final state = GoRouterState.of(context);
      final uri = state.uri;
      final totalFromUrl = int.tryParse(uri.queryParameters['total'] ?? '0') ?? 0;
      if (totalFromUrl > 0) {
        return totalFromUrl;
      }
    }
    
    // Пересчитываем на основе площади
    final area = int.tryParse(areaStr) ?? _area;
    
    if (area <= 0) {
      return minPrice; // Возвращаем минимум если площадь не указана
    }
    
    // Используем новую логику расчета
    return _calculatePrice(area);
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

    // Пересчитываем цену на основе текущей площади
    final baseTotal = _area > 0 
        ? _calculateTotalPrice(tariffId, _area.toString())
        : minPrice;
    
    int finalTotal = baseTotal;
    if (_promoApplied) {
      final discountedPrice = (baseTotal * 0.9).round();
      finalTotal = discountedPrice < minPrice ? minPrice : discountedPrice;
    }
    
    // Проверяем, можно ли оформить заказ (площадь должна быть указана для всех тарифов, кроме мебели)
    final canSubmit = tariffId == 'furniture' || 
                      (_area > 0 && _areaController.text.trim().isNotEmpty && _formKey.currentState?.validate() == true);

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
                      // Показываем параметры корпоративного тарифа
                      if (tariffId == 'corporate') ...[
                        if (uri.queryParameters['objects'] != null)
                          _OrderDetailRow(
                            label: 'Количество объектов',
                            value: uri.queryParameters['objects']!,
                          ),
                        if (uri.queryParameters['frequency'] != null)
                          _OrderDetailRow(
                            label: 'Частота уборок',
                            value: _getFrequencyLabel(uri.queryParameters['frequency']!),
                          ),
                        if (uri.queryParameters['cleaners'] != null)
                          _OrderDetailRow(
                            label: 'Клинеров на объект',
                            value: uri.queryParameters['cleaners']!,
                          ),
                      ],
                      if (tariffId != 'furniture')
                        _OrderDetailRow(
                          label: 'Площадь',
                          value: _area > 0 ? '$_area м²' : 'Не указана',
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
                        value: '${(_area > 0 ? _calculatePrice(_area) : minPrice).toStringAsFixed(0)} ₸',
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

            // ПЛОЩАДЬ - ОБЯЗАТЕЛЬНОЕ ПОЛЕ ДЛЯ ВВОДА
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.square_foot,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Площадь квартиры или дома',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            if (tariffId != 'furniture') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ОБЯЗАТЕЛЬНО',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tariffId == 'furniture'
                              ? 'Укажите площадь (необязательно)'
                              : 'Укажите площадь для расчета стоимости\nМинимальная стоимость: 20,000 ₸',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _areaController,
                          autofocus: _area == 0 && tariffId != 'furniture',
                          decoration: InputDecoration(
                            labelText: 'Площадь (м²)',
                            hintText: 'Площадь, м²',
                            prefixIcon: const Icon(Icons.square_foot),
                            suffixText: 'м²',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            // Разрешаем только цифры
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            // Для тарифа мебели площадь необязательна
                            if (tariffId == 'furniture') {
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, укажите площадь';
                            }
                            final areaValue = int.tryParse(value);
                            if (areaValue == null || areaValue < 1) {
                              return 'Минимальное значение: 1 м²';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final areaValue = int.tryParse(value);
                            if (areaValue != null && areaValue > 0) {
                              setState(() {
                                _area = areaValue;
                              });
                              // Валидируем форму при изменении
                              _formKey.currentState?.validate();
                            } else if (value.isEmpty) {
                              setState(() {
                                _area = 0;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_area > 0 && tariffId != 'furniture')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Стоимость:',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '${_calculatePrice(_area)} ₸',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                if (_area <= thresholdArea)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Применена минимальная стоимость',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.orange,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                                if (_area > thresholdArea)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '$minPrice ₸ + (${_area - thresholdArea} м² × $pricePerSquareMeter ₸/м²)',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.credit_card,
                              label: 'Карта',
                              subtitle: 'Visa/MC',
                              isSelected: _paymentMethod == 'card',
                              onTap: () => setState(() => _paymentMethod = 'card'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodCard(
                              icon: Icons.money,
                              label: 'Наличные',
                              subtitle: 'При получении',
                              isSelected: _paymentMethod == 'cash',
                              onTap: () => setState(() => _paymentMethod = 'cash'),
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
                      onPressed: (_saving || !mounted || !canSubmit) ? null : _handleConfirm,
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

