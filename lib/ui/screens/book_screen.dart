import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/book_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/mini_player.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// يفتح القارئ عند موضع
void openReader(BuildContext context, BookPosition pos) =>
    context.push('/book/read?s=${pos.section}&p=${pos.paragraph}');

/// تبويب «الكتاب»: أكمل القراءة + الفهرس
class BookScreen extends ConsumerWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indexAsync = ref.watch(readerIndexProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: Column(
            children: [
              Expanded(
                child: indexAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('تعذّر فتح الكتاب: $e')),
                  data: (index) => _Contents(index: index),
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

class _Contents extends ConsumerWidget {
  const _Contents({required this.index});

  final ReaderIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final book = index.book;
    final current = ref.watch(readingPositionProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'الكتاب',
            subtitle: '${book.title} لابن قيم الجوزية',
          ),
        ),
        SliverToBoxAdapter(
          child: _ContinueReadingCard(index: index, position: current),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.xxs,
              0,
            ),
            child: Row(
              children: [
                Expanded(child: Text('الفهرس', style: text.titleMedium)),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: colors.textMuted,
                  tooltip: 'بحث في الكتاب',
                  onPressed: () => showSearch(
                    context: context,
                    delegate: BookSearchDelegate(index),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: book.sections.length,
          itemBuilder: (_, i) {
            final section = book.sections[i];
            final lessons = book.lessonsInSection(i);
            final isCurrent = current?.section == i;
            return Material(
              color: isCurrent ? colors.accentContainer : Colors.transparent,
              child: InkWell(
                onTap: () => openReader(context, BookPosition(i, 0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm - 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: isCurrent
                                    ? AppTypography.medium
                                    : AppTypography.regular,
                                color:
                                    isCurrent ? colors.onAccentContainer : null,
                              ),
                            ),
                            if (lessons.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.headphones_outlined,
                                    size: 12,
                                    color: colors.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    lessons.length == 1
                                        ? 'الدرس ${lessons.first}'
                                        : 'الدروس ${lessons.first}–${lessons.last}',
                                    style: text.labelSmall
                                        ?.copyWith(color: colors.textMuted),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${section.page}',
                        style:
                            text.labelMedium?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Text(
              '${book.edition}.\nالمصدر: ${book.source}. أُثبت المتن دون الحواشي، والعناوين من وضع المحقق.',
              style: text.labelSmall?.copyWith(color: colors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.index, required this.position});

  final ReaderIndex index;
  final BookPosition? position;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final pos = position ?? const BookPosition(0, 0);
    final section = index.book.sections[pos.section];
    final progress = index.progressOf(pos);
    final fresh = position == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Material(
        color: colors.header,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openReader(context, pos),
          child: Stack(
            children: [
              Positioned.fill(
                child: IslamicPattern(
                  color: colors.gold.withValues(alpha: 0.2),
                  cellSize: 46,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fresh
                          ? 'ابدأ القراءة'
                          : 'أكمل القراءة، ص ${section.page}',
                      style: text.labelMedium
                          ?.copyWith(color: colors.onHeaderMuted),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      section.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: colors.onHeader),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: colors.onGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 3,
                                  color: colors.gold,
                                  backgroundColor: colors.onHeaderTrack,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs - 2),
                              Text(
                                'قرأت ${(progress * 100).round()}% من الكتاب',
                                style: text.labelSmall
                                    ?.copyWith(color: colors.onHeaderMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// البحث في نص الكتاب
class BookSearchDelegate extends SearchDelegate<void> {
  BookSearchDelegate(this.index)
      : super(
          searchFieldLabel: 'ابحث في الكتاب',
          keyboardType: TextInputType.text,
        );

  final ReaderIndex index;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'مسح',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_forward_rounded),
        tooltip: 'رجوع',
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    if (query.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'اكتب كلمتين على الأقل، مثل: الدعاء، التوبة، القلب',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      );
    }
    final hits = index.search(query);
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'لا نتائج لـ «$query». جرّب كلمة أخرى أو صيغة أقصر.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      );
    }
    return ListView.separated(
      itemCount: hits.length + 1,
      separatorBuilder: (_, __) => const Divider(indent: AppSpacing.lg),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              hits.length >= 100 ? 'أول 100 نتيجة' : '${hits.length} نتيجة',
              style: text.labelMedium?.copyWith(color: colors.textMuted),
            ),
          );
        }
        final hit = hits[i - 1];
        final section = index.book.sections[hit.position.section];
        return ListTile(
          title: Text(
            hit.snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium,
          ),
          subtitle: Text(
            '${section.title}، ص ${section.page}',
            style: text.labelSmall?.copyWith(color: colors.textMuted),
          ),
          onTap: () {
            close(context, null);
            openReader(context, hit.position);
          },
        );
      },
    );
  }
}
