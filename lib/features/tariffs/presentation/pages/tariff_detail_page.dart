import 'package:flutter/material.dart';
import 'package:cleanapp/core/data/services_data.dart';
import 'package:go_router/go_router.dart';

class TariffDetailPage extends StatelessWidget {
  final String tariffId;

  const TariffDetailPage({
    super.key,
    required this.tariffId,
  });

  @override
  Widget build(BuildContext context) {
    // Безопасная проверка существования тарифа
    final tariff = ServicesData.tariffs.firstWhere(
      (t) => t.id == tariffId,
      orElse: () {
        // Если тариф не найден, возвращаем первый доступный или показываем ошибку
        if (ServicesData.tariffs.isEmpty) {
          throw Exception('Тарифы не найдены');
        }
        return ServicesData.tariffs.first;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tariff.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      tariff.icon,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tariff.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tariff.subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tariff.price,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Что входит:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...tariff.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )),
            if (tariff.description != null) ...[
              const SizedBox(height: 24),
              Text(
                tariff.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to calendar with tariff info
                  context.go('/calendar?tariff=$tariffId&name=${tariff.name}');
                },
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
          ],
        ),
      ),
    );
  }
}

