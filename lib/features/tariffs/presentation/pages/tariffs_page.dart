import 'package:flutter/material.dart';
import 'package:cleanapp/core/data/services_data.dart';
import 'package:cleanapp/core/models/tariff.dart';
import 'package:cleanapp/core/widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class TariffsPage extends StatelessWidget {
  const TariffsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Тарифы'),
            Text(
              'Выберите подходящий вариант уборки',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ServicesData.tariffs.length,
        itemBuilder: (context, index) {
          final tariff = ServicesData.tariffs[index];
          return _TariffCard(
            tariff: tariff,
            onTap: () => context.go('/tariff/${tariff.id}'),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}

class _TariffCard extends StatelessWidget {
  final Tariff tariff;
  final VoidCallback onTap;

  const _TariffCard({
    required this.tariff,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tariff.popular)
                Align(
                  alignment: Alignment.topRight,
                  child: Chip(
                    label: const Text('Популярно'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              if (tariff.savings != null)
                Align(
                  alignment: Alignment.topLeft,
                  child: Chip(
                    label: Text(tariff.savings!),
                    backgroundColor: Colors.green[100],
                    labelStyle: TextStyle(color: Colors.green[900]),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        tariff.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tariff.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tariff.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tariff.price,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...tariff.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (tariff.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  tariff.description!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('Выбрать тариф'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

