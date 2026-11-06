import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/annotation_widgets.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/mini_player.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Kind {
  all('الكل'),
  bookmarks('العلامات'),
  notes('الملاحظات');

  const _Kind(this.label);
  final String label;
}

final _kindProvider = StateProvider.autoDispose<_Kind>((ref) => _Kind.all);

/// «علاماتي» — كل العلامات والملاحظات من جميع الدروس، الأحدث أولاً
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = ref.watch(_kindProvider);
    final all = ref.watch(annotationsProvider).all;
    final items = switch (kind) {
      _Kind.all => all,
      _Kind.bookmarks => all.where((i) => !i.isNote).toList(),
      _Kind.notes => all.where((i) => i.isNote).toList(),
    };
    final titles = {
      for (final l in ref.watch(lessonsProvider).valueOrNull ?? const [])
        l.lesson.id: l.lesson,
    };

    void open(AnnotationItem item) {
      final lesson = titles[item.lessonId];
      if (lesson == null) return;
      final player = ref.read(playerProvider.notifier);
      final at = Duration(seconds: item.position);
      if (ref.read(playerProvider).currentLesson?.id == lesson.id) {
        player.seek(at);
      } else {
        player.play(lesson, startPosition: at);
      }
      context.push('/player/${lesson.id}');
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const PageHeader(
                      title: 'علاماتي',
                      subtitle:
                          'العلامات والملاحظات التي حفظتها أثناء الاستماع',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          for (final k in _Kind.values)
                            ChoiceChip(
                              label: Text(k.label),
                              selected: k == kind,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  ref.read(_kindProvider.notifier).state = k,
                            ),
                        ],
                      ),
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xxxl,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bookmarks_outlined,
                              size: 40,
                              color: colors.ringTrack,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'احفظ المواضع المهمة أثناء الاستماع',
                              style: text.titleSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'اضغط «علامة» أو «ملاحظة» في المشغّل، وستجدها هنا لتعود إليها متى شئت.',
                              style: text.bodySmall
                                  ?.copyWith(color: colors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      for (final item in items)
                        AnnotationTile(
                          item: item,
                          lessonTitle: titles[item.lessonId]?.title,
                          onTap: () => open(item),
                        ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              const MiniPlayer(),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }
}
