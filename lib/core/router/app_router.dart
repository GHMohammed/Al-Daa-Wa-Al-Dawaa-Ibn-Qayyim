import 'package:al_daa_wal_dawaa/ui/screens/home_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/player_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/progress_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  /// مفتاح المتصفح العام — يُستخدم لإظهار dialogs من خارج شجرة الـ widget
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/player/:lessonId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['lessonId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('معرّف الدرس غير صالح')),
            );
          }
          return PlayerScreen(lessonId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('الصفحة غير موجودة: ${state.uri}'),
      ),
    ),
  );
}
