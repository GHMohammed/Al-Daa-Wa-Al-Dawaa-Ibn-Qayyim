import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شريط التنقل السفلي المشترك
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (currentIndex != 0) context.go('/');
          case 1:
            if (currentIndex != 1) context.go('/progress');
          case 2:
            if (currentIndex != 2) context.go('/settings');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights),
          label: 'التقدم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
    );
  }
}
