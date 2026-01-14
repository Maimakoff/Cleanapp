import 'package:flutter/material.dart';
import 'tab_bar.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Отключаем SafeArea снизу, так как bottomNavigationBar сам использует SafeArea
        child: child,
      ),
      bottomNavigationBar: const CustomTabBar(),
      resizeToAvoidBottomInset: false, // Предотвращаем изменение размера при появлении клавиатуры
    );
  }
}

