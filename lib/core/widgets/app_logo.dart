import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  final MainAxisAlignment alignment;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        // Логотип
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            // Fallback если изображение не найдено
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.cleaning_services,
                color: Colors.white,
                size: size! * 0.6,
              ),
            );
          },
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cleanapp',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Чистота в один клик',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
