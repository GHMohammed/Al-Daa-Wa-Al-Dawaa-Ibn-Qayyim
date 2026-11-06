import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:flutter/material.dart';

/// رأس الصفحات الرئيسية: عنوان وسطر وصفي فوق زخرفة باهتة تتلاشى نحو الأسفل
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
  });

  final String title;
  final String? subtitle;

  /// محتوى إضافي أسفل العنوان (مثل شريط الإنجاز)
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Stack(
      children: [
        Positioned.fill(
          child: IslamicPattern(
            color: colors.pattern.withValues(alpha: 0.28),
            cellSize: 56,
            fadeToBottom: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.paddingOf(context).top + AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineSmall),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: text.bodySmall?.copyWith(color: colors.textMuted),
                ),
              if (child != null) ...[
                const SizedBox(height: AppSpacing.lg),
                child!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
