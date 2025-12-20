import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../widgets/mobile_layout.dart';
import '../models/booking.dart';
import '../services/supabase_service.dart';

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

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru', null).then((_) {
      _loadBookings();
    });
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

  bool _isTimeSlotAvailable(DateTime date, String time) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final isBooked = _bookings.any(
      (b) => b['date'] == dateStr && b['time'] == time,
    );
    final isSelected = _selectedDates.any(
      (s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr && s.time == time,
    );
    return !isBooked && !isSelected;
  }

  bool _isDateAvailable(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAfter(todayOnly) || dateOnly.isAtSameMomentAs(todayOnly);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Это время уже занято')),
      );
      return;
    }

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

    final uri = Uri(
      path: '/booking',
      queryParameters: {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDates[0].date),
        'time': _selectedDates[0].time,
      },
    );
    context.push(uri.toString());
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
                      Text(
                        'Выбранные даты:',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
                                '${DateFormat('d MMM').format(selected.date)} ${selected.time}',
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
                      lastDay: DateTime.now().add(const Duration(days: 365)),
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
                    'Выберите время на ${DateFormat('d MMMM', 'ru').format(_currentSelectingDate!)}',
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

