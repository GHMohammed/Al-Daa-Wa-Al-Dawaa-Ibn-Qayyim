import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:al_daa_wal_dawaa/ui/screens/main_shell.dart';
import 'package:al_daa_wal_dawaa/ui/screens/reader_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/player_screen.dart';
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
      // الأقسام الخمسة في إطار واحد قابل للسحب؛ ‎/?tab=N يفتح قسماً بعينه
      GoRoute(
        path: '/',
        builder: (context, state) => MainShell(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/book', redirect: (_, __) => '/?tab=1'),
      GoRoute(
        path: '/book/read',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ReaderScreen(
            initial: BookPosition(
              int.tryParse(q['s'] ?? '') ?? 0,
              int.tryParse(q['p'] ?? '') ?? 0,
            ),
          );
        },
      ),
      GoRoute(path: '/bookmarks', redirect: (_, __) => '/?tab=2'),
      GoRoute(path: '/progress', redirect: (_, __) => '/?tab=3'),
      GoRoute(path: '/settings', redirect: (_, __) => '/?tab=4'),
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
