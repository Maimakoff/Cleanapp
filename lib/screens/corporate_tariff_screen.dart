import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_layout.dart';

class CorporateTariffScreen extends StatefulWidget {
  const CorporateTariffScreen({super.key});

  @override
  State<CorporateTariffScreen> createState() => _CorporateTariffScreenState();
}

class _CorporateTariffScreenState extends State<CorporateTariffScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Поля формы
  int _numberOfObjects = 1;
  int _totalArea = 100; // Общая площадь всех объектов
  String _frequency = 'weekly'; // Частота уборок
  bool _includeWindows = false;
  bool _includeDeepCleaning = false;
  bool _includeCarpetCleaning = false;
  bool _includeSanitization = false;
  String _cleaningTime = 'morning'; // Время уборки
  int _numberOfCleaners = 1; // Количество клинеров

  // Опции частоты
  final Map<String, Map<String, dynamic>> _frequencyOptions = {
    'daily': {'label': 'Ежедневно', 'multiplier': 30.0, 'discount': 0.15},
    'weekly': {'label': 'Еженедельно', 'multiplier': 4.0, 'discount': 0.10},
    'biweekly': {'label': '2 раза в неделю', 'multiplier': 8.0, 'discount': 0.12},
    'monthly': {'label': 'Раз в месяц', 'multiplier': 1.0, 'discount': 0.0},
  };

  // Опции времени
  final Map<String, String> _timeOptions = {
    'morning': 'Утро (9:00 - 12:00)',
    'afternoon': 'День (12:00 - 17:00)',
    'evening': 'Вечер (17:00 - 20:00)',
    'flexible': 'Гибкий график',
  };

  int _calculatePrice() {
    // Базовая цена за м² для корпоративных клиентов
    const int basePricePerSqm = 350; // Скидка для корпоративных клиентов
    
    // Базовая стоимость
    int basePrice = basePricePerSqm * _totalArea;
    
    // Умножаем на частоту
    final frequencyData = _frequencyOptions[_frequency]!;
    double frequencyMultiplier = frequencyData['multiplier'] as double;
    double discount = frequencyData['discount'] as double;
    
    int monthlyPrice = (basePrice * frequencyMultiplier).round();
    
    // Применяем скидку за частоту
    monthlyPrice = (monthlyPrice * (1 - discount)).round();
    
    // Дополнительные услуги
    if (_includeWindows) {
      monthlyPrice += (_totalArea * 50 * frequencyMultiplier * (1 - discount)).round();
    }
    if (_includeDeepCleaning) {
      monthlyPrice += (monthlyPrice * 0.2).round(); // +20%
    }
    if (_includeCarpetCleaning) {
      monthlyPrice += (_totalArea * 30 * frequencyMultiplier * (1 - discount)).round();
    }
    if (_includeSanitization) {
      monthlyPrice += (monthlyPrice * 0.15).round(); // +15%
    }
    
    // Скидка за количество объектов (оптовая скидка)
    if (_numberOfObjects > 5) {
      monthlyPrice = (monthlyPrice * 0.95).round(); // -5%
    }
    if (_numberOfObjects > 10) {
      monthlyPrice = (monthlyPrice * 0.90).round(); // -10%
    }
    
    return monthlyPrice;
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final monthlyPrice = _calculatePrice();
      
      // Переходим к календарю с параметрами корпоративного тарифа
      context.push(
        '/calendar?tariff=corporate'
        '&name=${Uri.encodeComponent("Корпоративный тариф")}'
        '&total=$monthlyPrice'
        '&area=$_totalArea'
        '&objects=$_numberOfObjects'
        '&frequency=$_frequency'
        '&cleaners=$_numberOfCleaners',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = _calculatePrice();
    final frequencyLabel = _frequencyOptions[_frequency]!['label'] as String;

    return MobileLayout(
      child: Form(
        key: _formKey,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Корпоративный тариф',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Конструктор уборки для бизнеса',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Основные параметры
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Основные параметры',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Количество объектов
                        Text(
                          'Количество объектов',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _numberOfObjects.toDouble(),
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: '$_numberOfObjects ${_numberOfObjects == 1 ? 'объект' : _numberOfObjects < 5 ? 'объекта' : 'объектов'}',
                                onChanged: (value) {
                                  setState(() {
                                    _numberOfObjects = value.toInt();
                                  });
                                },
                              ),
                            ),
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_numberOfObjects',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Общая площадь
                        Text(
                          'Общая площадь всех объектов (м²)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _totalArea.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Введите общую площадь',
                            prefixIcon: Icon(Icons.square_foot),
                            suffixText: 'м²',
                          ),
                          onChanged: (value) {
                            final area = int.tryParse(value);
                            if (area != null && area > 0) {
                              setState(() {
                                _totalArea = area;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Укажите площадь';
                            }
                            final area = int.tryParse(value);
                            if (area == null || area <= 0) {
                              return 'Введите корректное значение';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Частота уборок
                        Text(
                          'Частота уборок',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _frequencyOptions.entries.map((entry) {
                            final isSelected = _frequency == entry.key;
                            return FilterChip(
                              label: Text(entry.value['label'] as String),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _frequency = entry.key;
                                  });
                                }
                              },
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Количество клинеров
                        Text(
                          'Количество клинеров на объект',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _numberOfCleaners.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: '$_numberOfCleaners ${_numberOfCleaners == 1 ? 'клинер' : _numberOfCleaners < 5 ? 'клинера' : 'клинеров'}',
                                onChanged: (value) {
                                  setState(() {
                                    _numberOfCleaners = value.toInt();
                                  });
                                },
                              ),
                            ),
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_numberOfCleaners',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Время уборки
                        Text(
                          'Предпочтительное время уборки',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _cleaningTime,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          items: _timeOptions.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _cleaningTime = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Дополнительные услуги
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дополнительные услуги',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _ServiceCheckbox(
                          title: 'Мойка окон',
                          subtitle: '+50 ₸/м²',
                          value: _includeWindows,
                          onChanged: (value) {
                            setState(() {
                              _includeWindows = value;
                            });
                          },
                        ),
                        _ServiceCheckbox(
                          title: 'Генеральная уборка',
                          subtitle: '+20% к стоимости',
                          value: _includeDeepCleaning,
                          onChanged: (value) {
                            setState(() {
                              _includeDeepCleaning = value;
                            });
                          },
                        ),
                        _ServiceCheckbox(
                          title: 'Чистка ковров',
                          subtitle: '+30 ₸/м²',
                          value: _includeCarpetCleaning,
                          onChanged: (value) {
                            setState(() {
                              _includeCarpetCleaning = value;
                            });
                          },
                        ),
                        _ServiceCheckbox(
                          title: 'Дезинфекция',
                          subtitle: '+15% к стоимости',
                          value: _includeSanitization,
                          onChanged: (value) {
                            setState(() {
                              _includeSanitization = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Итоговая стоимость
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Расчет стоимости',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _PriceRow(
                          label: 'Количество объектов',
                          value: '$_numberOfObjects',
                        ),
                        _PriceRow(
                          label: 'Общая площадь',
                          value: '$_totalArea м²',
                        ),
                        _PriceRow(
                          label: 'Частота уборок',
                          value: frequencyLabel,
                        ),
                        _PriceRow(
                          label: 'Клинеров на объект',
                          value: '$_numberOfCleaners',
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Стоимость в месяц:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${monthlyPrice.toStringAsFixed(0)} ₸',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        if (_frequencyOptions[_frequency]!['discount'] as double > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Скидка за частоту: ${((_frequencyOptions[_frequency]!['discount'] as double) * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

              // Кнопка продолжения
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Выбрать дату и время',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCheckbox extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ServiceCheckbox({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

