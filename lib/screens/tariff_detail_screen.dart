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

  Tariff? get tariff {
    try {
      return TariffData.tariffs.firstWhere((t) => t.id == widget.tariffId);
    } catch (e) {
      return null;
    }
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
    
    return pricePerSqm * _area;
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

            // Area Selector (for area-based tariffs)
            if (widget.tariffId != 'furniture')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Площадь квартиры',
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
                              child: Slider(
                                value: _area.toDouble(),
                                min: 20,
                                max: 200,
                                divisions: 36,
                                label: '$_area м²',
                                onChanged: (value) {
                                  setState(() {
                                    _area = value.toInt();
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
                                '$_area м²',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

