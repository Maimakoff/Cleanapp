import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../widgets/mobile_layout.dart';
import 'package:cleanapp/core/models/booking.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import '../core/utils/date_formatter.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime? _currentSelectingDate;
  final List<SelectedDate> _selectedDates = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isBookingMode = false; // Режим бронирования (после выбора тарифа)
  String? _currentTariffId; // ID текущего тарифа

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  void initState() {
    super.initState();
    // Проверяем, открыт ли календарь из выбора тарифа
    // Используем addPostFrameCallback, так как context доступен только после первого build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = GoRouterState.of(context);
        final uri = state.uri;
        setState(() {
          _isBookingMode = uri.queryParameters.containsKey('tariff');
          _currentTariffId = uri.queryParameters['tariff'];
        });
      }
    });
    
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await SupabaseService.getBookedDates();
      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  bool _isDateBooked(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final bookedCount = _bookings.where((b) => b['date'] == dateStr).length;
    return bookedCount >= _timeSlots.length;
  }

  // Получить список заблокированных временных слотов для даты
  List<String> _getBlockedTimeSlots(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final blockedSlots = <String>{};
    
    // Находим все забронированные времена на эту дату
    final bookedTimes = _bookings
        .where((b) => b['date'] == dateStr)
        .map((b) => b['time'] as String)
        .toList();
    
    // Для каждого забронированного времени блокируем 2 часа до и после
    for (final bookedTime in bookedTimes) {
      final bookedHour = int.tryParse(bookedTime.split(':')[0]) ?? 0;
      
      // Блокируем 2 часа до и после (включая само время)
      for (int i = -2; i <= 2; i++) {
        final blockedHour = bookedHour + i;
        if (blockedHour >= 9 && blockedHour <= 20) {
          final blockedTime = '${blockedHour.toString().padLeft(2, '0')}:00';
          blockedSlots.add(blockedTime);
        }
      }
    }
    
    return blockedSlots.toList();
  }

  bool _isTimeSlotAvailable(DateTime date, String time) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Проверяем, забронировано ли это время напрямую
    final isBooked = _bookings.any(
      (b) => b['date'] == dateStr && b['time'] == time,
    );
    
    // Проверяем, заблокировано ли это время (2 часа до/после другого бронирования)
    final blockedSlots = _getBlockedTimeSlots(date);
    final isBlocked = blockedSlots.contains(time);
    
    // Проверяем, выбрано ли это время пользователем
    final isSelected = _selectedDates.any(
      (s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr && s.time == time,
    );
    
    return !isBooked && !isBlocked && !isSelected;
  }

  // Получить максимальное количество дат для тарифа
  int? _getMaxDatesForTariff(String? tariffId) {
    if (tariffId == null) return null; // Без ограничений для обычного календаря
    
    switch (tariffId) {
      case 'start':
        return 1;
      case 'comfort':
        return 4;
      case 'premium':
        return 8;
      case 'lux':
        return 12;
      case 'after-renovation':
      case 'furniture':
        return 1;
      default:
        return null; // Без ограничений для других тарифов
    }
  }

  bool _isDateAvailable(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Проверяем, что дата не в прошлом
    if (dateOnly.isBefore(todayOnly)) {
      return false;
    }
    
    // Если это режим бронирования (после выбора тарифа), ограничиваем 1 месяц
    if (_isBookingMode) {
      final maxDate = DateTime(today.year, today.month + 1, today.day);
      final maxDateOnly = DateTime(maxDate.year, maxDate.month, maxDate.day);
      return dateOnly.isBefore(maxDateOnly) || dateOnly.isAtSameMomentAs(maxDateOnly);
    }
    
    // Для обычного календаря (вкладка) - без ограничений по дате
    return true;
  }

  void _handleDateSelect(DateTime selectedDay, DateTime focusedDay) {
    if (!_isDateAvailable(selectedDay) || _isDateBooked(selectedDay)) return;

    setState(() {
      _selectedDay = selectedDay;
      _currentSelectingDate = selectedDay;
    });
  }

  void _handleTimeSelect(String time) {
    if (_currentSelectingDate == null) return;
    if (!_isTimeSlotAvailable(_currentSelectingDate!, time)) {
      final blockedSlots = _getBlockedTimeSlots(_currentSelectingDate!);
      final isBlocked = blockedSlots.contains(time);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked
                ? 'Это время заблокировано (за 2 часа до/после другого бронирования)'
                : 'Это время уже занято',
          ),
        ),
      );
      return;
    }

    // Проверяем ограничение на количество дат для тарифа
    final maxDates = _getMaxDatesForTariff(_currentTariffId);
    
    if (maxDates != null) {
      // Для тарифов с лимитом 1 (start, after-renovation, furniture) заменяем предыдущую дату
      if (maxDates == 1) {
        setState(() {
          _selectedDates.clear();
          _selectedDates.add(SelectedDate(
            date: _currentSelectingDate!,
            time: time,
          ));
          _currentSelectingDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разовая уборка: выбрана дата'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Для остальных тарифов проверяем лимит
      if (_selectedDates.length >= maxDates) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Для этого тарифа можно выбрать максимум $maxDates ${maxDates == 1 ? 'дату' : maxDates < 5 ? 'даты' : 'дат'}. Удалите одну из выбранных дат, чтобы добавить новую.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Добавляем новую дату
    setState(() {
      _selectedDates.add(SelectedDate(
        date: _currentSelectingDate!,
        time: time,
      ));
      _currentSelectingDate = null;
    });
  }

  void _removeSelectedDate(int index) {
    setState(() {
      _selectedDates.removeAt(index);
    });
  }

  void _handleContinue() {
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время')),
      );
      return;
    }

    // Получаем параметры из URL (если есть)
    final state = GoRouterState.of(context);
    final uri = state.uri;
    
    final queryParams = <String, String>{
      'date': DateFormat('yyyy-MM-dd').format(_selectedDates[0].date),
      'time': _selectedDates[0].time,
    };
    
    // Передаем параметры тарифа, если они есть
    if (uri.queryParameters.containsKey('tariff')) {
      queryParams['tariff'] = uri.queryParameters['tariff']!;
    }
    if (uri.queryParameters.containsKey('name')) {
      queryParams['name'] = uri.queryParameters['name']!;
    }
    if (uri.queryParameters.containsKey('total')) {
      queryParams['total'] = uri.queryParameters['total']!;
    }
    if (uri.queryParameters.containsKey('area')) {
      queryParams['area'] = uri.queryParameters['area']!;
    }

    final bookingUri = Uri(
      path: '/booking',
      queryParameters: queryParams,
    );
    context.push(bookingUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MobileLayout(
      child: Column(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите дату и время',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Удобное время для уборки',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          // Selected Dates
          if (_selectedDates.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getMaxDatesForTariff(_currentTariffId) == 1
                                  ? 'Выбранная дата:' 
                                  : 'Выбранные даты:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (_currentTariffId != null)
                            Builder(
                              builder: (context) {
                                final maxDates = _getMaxDatesForTariff(_currentTariffId);
                                if (maxDates == null) return const SizedBox.shrink();
                                
                                final remaining = maxDates - _selectedDates.length;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: remaining > 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    remaining > 0
                                        ? 'Осталось: $remaining ${remaining == 1 ? 'дата' : remaining < 5 ? 'даты' : 'дат'}'
                                        : 'Лимит достигнут',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: remaining > 0
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          _selectedDates.length,
                          (index) {
                            final selected = _selectedDates[index];
                            return Chip(
                              label: Text(
                                '${DateFormatter.formatDateShort(selected.date)} ${selected.time}',
                              ),
                              onDeleted: () => _removeSelectedDate(index),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              deleteIconColor:
                                  Theme.of(context).colorScheme.primary,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: _isBookingMode
                          ? DateTime(DateTime.now().year, DateTime.now().month + 1, DateTime.now().day)
                          : DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: _handleDateSelect,
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      enabledDayPredicate: (day) {
                        return _isDateAvailable(day);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      locale: 'ru_RU',
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Месяц',
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Time Slots
          if (_currentSelectingDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите время на ${DateFormatter.formatDateMonth(_currentSelectingDate!)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((time) {
                      final available =
                          _isTimeSlotAvailable(_currentSelectingDate!, time);
                      final isSelected = _selectedDates.any(
                        (s) =>
                            isSameDay(s.date, _currentSelectingDate!) &&
                            s.time == time,
                      );

                      return FilterChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: available
                            ? (_) => _handleTimeSelect(time)
                            : null,
                        selectedColor:
                            Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : available
                                  ? null
                                  : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Continue Button
          if (_selectedDates.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  child: const Text(
                    'Перейти к оформлению',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

