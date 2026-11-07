import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/annotation_widgets.dart';
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

/// الدرس المختار للتصفية (null = كل الدروس)
final _lessonFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

/// «علاماتي» — كل العلامات والملاحظات من جميع الدروس، الأحدث أولاً
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = ref.watch(_kindProvider);
    final lessonFilter = ref.watch(_lessonFilterProvider);
    final all = ref.watch(annotationsProvider).all;
    final byKind = switch (kind) {
      _Kind.all => all,
      _Kind.bookmarks => all.where((i) => !i.isNote).toList(),
      _Kind.notes => all.where((i) => i.isNote).toList(),
    };
    // داخل درس واحد: الترتيب حسب الموضع في الصوت أنفع من تاريخ الإضافة
    final items = lessonFilter == null
        ? byKind
        : (byKind.where((i) => i.lessonId == lessonFilter).toList()
          ..sort((a, b) => a.position.compareTo(b.position)));
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
                    if (all.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xs,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final k in _Kind.values)
                              ChoiceChip(
                                label: Text(k.label),
                                selected: k == kind,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    ref.read(_kindProvider.notifier).state = k,
                              ),
                            _LessonFilterChip(
                              selected: lessonFilter,
                              all: all,
                              titles: {
                                for (final e in titles.entries)
                                  e.key: e.value.title,
                              },
                            ),
                          ],
                        ),
                      ),
                    if (lessonFilter != null && titles[lessonFilter] != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xxs,
                        ),
                        child: Text(
                          'الدرس $lessonFilter: ${titles[lessonFilter]!.title}',
                          style: text.titleSmall,
                        ),
                      ),
                    if (all.isNotEmpty && items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xxl,
                        ),
                        child: Column(
                          children: [
                            Text(
                              lessonFilter == null
                                  ? 'لا يوجد شيء من هذا النوع بعد'
                                  : 'لا يوجد شيء من هذا النوع في هذا الدرس',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium
                                  ?.copyWith(color: colors.textMuted),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(_kindProvider.notifier).state =
                                    _Kind.all;
                                ref.read(_lessonFilterProvider.notifier).state =
                                    null;
                              },
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                      )
                    else if (items.isEmpty)
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
                          // اسم الدرس مكرر إذا كانت القائمة لدرس واحد
                          lessonTitle: lessonFilter == null
                              ? titles[item.lessonId]?.title
                              : null,
                          onTap: () => open(item),
                        ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر «كل الدروس ▾» — يفتح قائمة بالدروس التي فيها علامات أو ملاحظات
class _LessonFilterChip extends ConsumerWidget {
  const _LessonFilterChip({
    required this.selected,
    required this.all,
    required this.titles,
  });

  final int? selected;
  final List<AnnotationItem> all;
  final Map<int, String> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    if (selected != null) {
      return InputChip(
        label: Text('الدرس $selected'),
        selected: true,
        showCheckmark: false,
        onPressed: () => _pick(context, ref),
        onDeleted: () => ref.read(_lessonFilterProvider.notifier).state = null,
        deleteButtonTooltipMessage: 'إلغاء تصفية الدرس',
      );
    }
    return ActionChip(
      avatar: Icon(Icons.filter_list_rounded, size: 18, color: colors.brand),
      label: const Text('كل الدروس'),
      onPressed: () => _pick(context, ref),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    // عدد العلامات والملاحظات لكل درس فيه شيء محفوظ
    final counts = <int, ({int marks, int notes})>{};
    for (final i in all) {
      final c = counts[i.lessonId] ?? (marks: 0, notes: 0);
      counts[i.lessonId] = i.isNote
          ? (marks: c.marks, notes: c.notes + 1)
          : (marks: c.marks + 1, notes: c.notes);
    }
    final lessons = counts.keys.toList()..sort();

    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final colors = ctx.colors;
        final text = Theme.of(ctx).textTheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scroll) => ListView(
            controller: scroll,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text('اختر درساً', style: text.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.select_all_rounded),
                title: const Text('كل الدروس'),
                selected: selected == null,
                selectedColor: colors.brand,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              for (final id in lessons)
                ListTile(
                  selected: selected == id,
                  selectedColor: colors.brand,
                  selectedTileColor: colors.accentContainer,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.accentContainer,
                    foregroundColor: colors.onAccentContainer,
                    child: Text('$id', style: const TextStyle(fontSize: 13)),
                  ),
                  title: Text(
                    titles[id] ?? 'الدرس $id',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (counts[id]!.marks > 0) 'علامات: ${counts[id]!.marks}',
                      if (counts[id]!.notes > 0)
                        'ملاحظات: ${counts[id]!.notes}',
                    ].join('، '),
                    style: text.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                  onTap: () => Navigator.pop(ctx, id),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    ref.read(_lessonFilterProvider.notifier).state = picked < 0 ? null : picked;
  }
}
