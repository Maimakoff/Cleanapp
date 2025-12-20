import 'package:flutter/material.dart';
import 'package:cleanapp/core/widgets/bottom_nav_bar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
      ),
      body: const Center(
        child: Text('Календарь - в разработке'),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

