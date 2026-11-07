import 'package:al_daa_wal_dawaa/ui/screens/book_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/bookmarks_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/home_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/progress_screen.dart';
import 'package:al_daa_wal_dawaa/ui/screens/settings_screen.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/mini_player.dart';
import 'package:flutter/material.dart';

/// الإطار المشترك للأقسام الخمسة: تنقل بالسحب يميناً ويساراً أو من الشريط السفلي،
/// ومشغّل مصغّر واحد فوق الشريط. كل قسم يحتفظ بحالته (موضع التمرير مثلاً).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  /// يأتي من المسار (‎/?tab=N) — مثلاً عند الرجوع للدروس من المشغّل
  final int initialTab;

  static const tabCount = 5;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialTab.clamp(0, MainShell.tabCount - 1);
  late final PageController _pages = PageController(initialPage: _index);

  static const _tabs = <Widget>[
    HomeScreen(),
    BookScreen(),
    BookmarksScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  void didUpdateWidget(MainShell old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _goTo(widget.initialTab);
  }

  void _goTo(int index) {
    index = index.clamp(0, MainShell.tabCount - 1);
    if (index == _index) return;
    // تبويب مجاور: انزلاق؛ أبعد من ذلك: قفزة مباشرة بدل المرور بالصفحات الوسطى
    if ((index - _index).abs() == 1) {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pages.jumpToPage(index);
    }
    setState(() => _index = index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // زر الرجوع من أي قسم يعيد إلى «الدروس» قبل الخروج من التطبيق
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              // في RTL يكون القسم التالي إلى اليسار، كترتيب الشريط السفلي
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [for (final tab in _tabs) _KeepAlive(child: tab)],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          onSelected: _goTo,
        ),
      ),
    );
  }
}

/// يبقي القسم حياً عند الانتقال لغيره (موضع التمرير، الفلاتر، ...)
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
