import 'package:flutter/material.dart';

/// يغطّي منطقة شريط الحالة بلون الخلفية حتى لا يمرّ المحتوى المُمرَّر تحت الساعة والأيقونات،
/// مع إبقاء رأس الصفحة (وزخرفته) ممتداً خلف الشريط عند أعلى التمرير.
class StatusBarScrim extends StatelessWidget {
  const StatusBarScrim({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
    );
  }
}
