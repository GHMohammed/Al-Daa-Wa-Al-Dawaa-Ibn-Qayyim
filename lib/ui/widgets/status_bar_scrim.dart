import 'package:flutter/material.dart';

/// يغطّي منطقة شريط الحالة بلون الخلفية حتى لا يمرّ المحتوى المُمرَّر تحت الساعة والأيقونات.
/// عند أعلى الصفحة يبقى شفافاً فتمتد زخرفة الرأس خلف الشريط بلا حدّ فاصل،
/// ويظهر تدريجياً مع أول تمرير.
class StatusBarScrim extends StatefulWidget {
  const StatusBarScrim({super.key, required this.child});

  final Widget child;

  @override
  State<StatusBarScrim> createState() => _StatusBarScrimState();
}

class _StatusBarScrimState extends State<StatusBarScrim> {
  final _opacity = ValueNotifier<double>(0);

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n, double top) {
    // التمرير الرأسي للصفحة نفسها فقط، لا القوائم الأفقية داخلها
    if (n.depth == 0 && n.metrics.axis == Axis.vertical && top > 0) {
      _opacity.value = (n.metrics.pixels / top).clamp(0.0, 1.0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) => _onScroll(n, top),
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: _opacity,
              builder: (context, opacity, _) => ColoredBox(
                color: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: opacity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
