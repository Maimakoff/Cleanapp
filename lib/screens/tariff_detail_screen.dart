import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_layout.dart';
import '../models/tariff.dart';

class TariffDetailScreen extends StatefulWidget {
  final String tariffId;

  const TariffDetailScreen({super.key, required this.tariffId});

  @override
  State<TariffDetailScreen> createState() => _TariffDetailScreenState();
}

class _TariffDetailScreenState extends State<TariffDetailScreen> {
  int _area = 50;
  final TextEditingController _areaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Tariff? get tariff {
    try {
      return TariffData.tariffs.firstWhere((t) => t.id == widget.tariffId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _areaController.text = _area.toString();
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
    _areaController.dispose();
    super.dispose();
  }

  int _calculatePrice() {
    if (tariff == null) return 0;
    
    if (widget.tariffId == 'furniture') {
      // Furniture cleaning has fixed prices
      return 0;
    }
    
    final pricePerSqm = int.tryParse(
      tariff!.price.replaceAll(RegExp(r'[^\d]'), ''),
    ) ?? 400;
    
    // Минимальная цена 20,000 ₸
    const int minPrice = 20000;
    
    // Если площадь меньше 50 м², возвращаем минимальную цену
    if (_area < 50) {
      return minPrice;
    }
    
    // Иначе цена за квадратный метр, но не меньше минимума
    final calculatedPrice = pricePerSqm * _area;
    return calculatedPrice < minPrice ? minPrice : calculatedPrice;
  }

  @override
  Widget build(BuildContext context) {
    if (tariff == null) {
      return const MobileLayout(
        child: Center(
          child: Text('Тариф не найден'),
        ),
      );
    }

    final totalPrice = _calculatePrice();

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tariff!.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          tariff!.subtitle,
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

            // Area Input (for area-based tariffs)
            if (widget.tariffId != 'furniture')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Площадь квартиры или дома',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Укажите площадь для расчета стоимости\nМинимальная стоимость: 20,000 ₸',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              labelText: 'Площадь (м²)',
                              hintText: 'Введите площадь',
                              prefixIcon: const Icon(Icons.square_foot),
                              suffixText: 'м²',
                              errorText: _areaController.text.isNotEmpty && 
                                  (int.tryParse(_areaController.text) == null || 
                                   int.tryParse(_areaController.text)! <= 0)
                                  ? 'Введите корректное значение'
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, укажите площадь';
                              }
                              final areaValue = int.tryParse(value);
                              if (areaValue == null || areaValue <= 0) {
                                return 'Введите корректное значение';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final areaValue = int.tryParse(value);
                              if (areaValue != null && areaValue > 0) {
                                setState(() {
                                  _area = areaValue;
                                });
                              } else if (value.isEmpty) {
                                setState(() {
                                  _area = 0;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_area > 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Стоимость:',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${_calculatePrice().toStringAsFixed(0)} ₸',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          if (_area > 0 && _area < 50)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Применена минимальная стоимость',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Price Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Стоимость',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.tariffId == 'furniture'
                                ? tariff!.price
                                : '${totalPrice.toStringAsFixed(0)} ₸',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Что входит',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...tariff!.features.map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // CTA Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Валидация формы
                    if (widget.tariffId != 'furniture') {
                      if (!_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пожалуйста, укажите площадь квартиры или дома'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      final areaValue = int.tryParse(_areaController.text);
                      if (areaValue == null || areaValue <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пожалуйста, укажите корректную площадь'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                    
                    context.push(
                      '/calendar?tariff=${widget.tariffId}&name=${Uri.encodeComponent(tariff!.name)}&total=$totalPrice&area=$_area',
                    );
                  },
                  child: const Text(
                    'Выбрать дату и время',
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
      ),
    );
  }
}

