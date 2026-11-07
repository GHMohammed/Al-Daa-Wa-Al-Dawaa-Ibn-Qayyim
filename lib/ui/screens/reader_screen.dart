import 'dart:async';

import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/core/utils/arabic_text.dart';
import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/book_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// ألوان صفحة القراءة — مستقلة عن ثيم التطبيق (فاتح/ورقي/داكن)
class _ReaderPalette {
  const _ReaderPalette({
    required this.bg,
    required this.ink,
    required this.muted,
    required this.quran,
    required this.accent,
    required this.line,
    required this.chip,
    required this.onChip,
    required this.dark,
  });

  final Color bg;
  final Color ink;
  final Color muted;
  final Color quran;
  final Color accent;
  final Color line;
  final Color chip;
  final Color onChip;
  final bool dark;

  static const light = _ReaderPalette(
    bg: Color(0xFFFBFBF8),
    ink: Color(0xFF1B2A22),
    muted: Color(0xFF6B7A72),
    quran: Color(0xFF17694A),
    accent: Color(0xFFA8862F),
    line: Color(0xFFE3E7E1),
    chip: Color(0xFFE6F0EA),
    onChip: Color(0xFF145C40),
    dark: false,
  );

  static const sepia = _ReaderPalette(
    bg: Color(0xFFF4ECDD),
    ink: Color(0xFF3B2F1E),
    muted: Color(0xFF8A775B),
    quran: Color(0xFF2F6B4C),
    accent: Color(0xFFA9822F),
    line: Color(0xFFE2D6BF),
    chip: Color(0xFFE8DCC4),
    onChip: Color(0xFF4A3B22),
    dark: false,
  );

  static const night = _ReaderPalette(
    bg: Color(0xFF0D1310),
    ink: Color(0xFFE3E9E5),
    muted: Color(0xFF8D9D95),
    quran: Color(0xFF7FCBA4),
    accent: Color(0xFFD5B366),
    line: Color(0xFF1E2925),
    chip: Color(0xFF17302A),
    onChip: Color(0xFF93D1B2),
    dark: true,
  );

  static _ReaderPalette of(ReaderTheme? theme, Brightness app) =>
      switch (theme) {
        ReaderTheme.light => light,
        ReaderTheme.sepia => sepia,
        ReaderTheme.dark => night,
        null => app == Brightness.dark ? night : light,
      };
}

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.initial});

  final BookPosition initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(readerIndexProvider);
    return indexAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('تعذّر فتح الكتاب: $e')),
      ),
      data: (index) => _Reader(index: index, initial: initial),
    );
  }
}

class _Reader extends ConsumerStatefulWidget {
  const _Reader({required this.index, required this.initial});

  final ReaderIndex index;
  final BookPosition initial;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();

  /// أعلى عنصر ظاهر — يحدّث الشريطين دون إعادة بناء النص
  late final ValueNotifier<int> _top;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _top = ValueNotifier(widget.index.indexOf(widget.initial));
    _positions.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final visible =
        _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.05);
    if (visible.isEmpty) return;
    final first = visible.reduce((a, b) => a.index < b.index ? a : b).index;
    if (first == _top.value) return;
    _top.value = first;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() => ref
      .read(readingPositionProvider.notifier)
      .save(widget.index.positionAt(_top.value));

  void _jumpTo(int itemIndex) {
    _scroll.jumpTo(index: itemIndex);
    _top.value = itemIndex;
    _save();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _save();
    _positions.itemPositions.removeListener(_onScroll);
    _top.dispose();
    super.dispose();
  }

  Future<void> _openLesson(int lessonId) async {
    final lessons = ref.read(lessonsProvider).valueOrNull;
    final item = lessons?.where((l) => l.lesson.id == lessonId).firstOrNull;
    if (item == null) return;
    if (ref.read(playerProvider).currentLesson?.id != lessonId) {
      unawaited(ref.read(playerProvider.notifier).play(item.lesson));
    }
    if (mounted) context.push('/player/$lessonId');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);
    final pal = _ReaderPalette.of(settings.theme, Theme.of(context).brightness);
    final index = widget.index;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: pal.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: pal.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                pal: pal,
                index: index,
                top: _top,
                onContents: () => _showContents(context, pal),
                onSettings: () => _showSettings(context),
              ),
              Expanded(
                child: SelectionArea(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _scroll,
                    itemPositionsListener: _positions,
                    initialScrollIndex: _top.value,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg + 2,
                      AppSpacing.sm,
                      AppSpacing.lg + 2,
                      AppSpacing.xxxl,
                    ),
                    itemCount: index.items.length,
                    itemBuilder: (_, i) => _ItemView(
                      item: index.items[i],
                      pal: pal,
                      settings: settings,
                      onLesson: _openLesson,
                    ),
                  ),
                ),
              ),
              _BottomBar(pal: pal, index: index, top: _top),
            ],
          ),
        ),
      ),
    );
  }

  void _showContents(BuildContext context, _ReaderPalette pal) {
    final book = widget.index.book;
    final current = widget.index.items[_top.value].section;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView.builder(
          controller: scroll,
          itemCount: book.sections.length,
          itemBuilder: (_, i) {
            final s = book.sections[i];
            final selected = i == current;
            return ListTile(
              selected: selected,
              selectedTileColor: ctx.colors.accentContainer,
              selectedColor: ctx.colors.onAccentContainer,
              title: Text(s.title, style: const TextStyle(fontSize: 14)),
              trailing: Text(
                arabicDigits(s.page),
                style: TextStyle(color: ctx.colors.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _jumpTo(widget.index.sectionStart[i]);
              },
            );
          },
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.pal,
    required this.index,
    required this.top,
    required this.onContents,
    required this.onSettings,
  });

  final _ReaderPalette pal;
  final ReaderIndex index;
  final ValueNotifier<int> top;
  final VoidCallback onContents;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pal.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            color: pal.muted,
            tooltip: 'رجوع',
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: top,
              builder: (_, i, __) => Text(
                index.book.sections[index.items[i].section].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: pal.muted, fontSize: 12.5),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            color: pal.muted,
            tooltip: 'الفهرس',
            onPressed: onContents,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            color: pal.muted,
            tooltip: 'إعدادات القراءة',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.pal, required this.index, required this.top});

  final _ReaderPalette pal;
  final ReaderIndex index;
  final ValueNotifier<int> top;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: top,
      builder: (_, i, __) {
        final pos = index.positionAt(i);
        final progress = index.progressOf(pos);
        final page = index.book.sections[pos.section].page;
        final style = TextStyle(color: pal.muted, fontSize: 11);
        return Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: pal.line)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text('ص ${arabicDigits(page)}', style: style),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: pal.accent,
                    backgroundColor: pal.line,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${arabicDigits((progress * 100).round())}٪', style: style),
            ],
          ),
        );
      },
    );
  }
}

class _ItemView extends StatelessWidget {
  const _ItemView({
    required this.item,
    required this.pal,
    required this.settings,
    required this.onLesson,
  });

  final ReaderItem item;
  final _ReaderPalette pal;
  final ReaderSettings settings;
  final ValueChanged<int> onLesson;

  static final _quran = RegExp('﴿[^﴾]*﴾');

  @override
  Widget build(BuildContext context) {
    final size = settings.fontSize;
    switch (item.kind) {
      case ReaderItemKind.heading:
        return Padding(
          padding: EdgeInsets.only(
            top: item.section == 0 ? AppSpacing.xs : AppSpacing.xxl,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            item.text,
            style: TextStyle(
              color: pal.accent,
              fontSize: size * 0.82,
              fontWeight: AppTypography.medium,
              height: 1.5,
            ),
          ),
        );
      case ReaderItemKind.fasl:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            '✦  فصل  ✦',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pal.accent,
              fontSize: size * 0.85,
              fontWeight: AppTypography.medium,
            ),
          ),
        );
      case ReaderItemKind.lesson:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: pal.chip,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onLesson(item.lesson!),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  children: [
                    Icon(Icons.headphones_rounded, size: 18, color: pal.onChip),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'استمع لشرح هذا الموضع — الدرس ${arabicDigits(item.lesson!)}',
                        style: TextStyle(color: pal.onChip, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.play_arrow_rounded, size: 20, color: pal.onChip),
                  ],
                ),
              ),
            ),
          ),
        );
      case ReaderItemKind.paragraph:
        return Padding(
          padding: EdgeInsets.only(bottom: size * 0.7),
          child: Text.rich(
            TextSpan(children: _spans(item.text)),
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: pal.ink,
              fontSize: size,
              height: settings.spacing.height,
            ),
          ),
        );
    }
  }

  /// الآيات بين ﴿﴾ بلون مميز
  List<InlineSpan> _spans(String text) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _quran.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(text: m.group(0), style: TextStyle(color: pal.quran)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final current = settings.theme ??
        (Theme.of(context).brightness == Brightness.dark
            ? ReaderTheme.dark
            : ReaderTheme.light);

    Widget label(String s) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(s,
              style: text.labelMedium?.copyWith(color: colors.textMuted)),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('إعدادات القراءة', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          label('حجم الخط'),
          Row(
            children: [
              const Text('ا', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: ReaderSettings.minFont,
                  max: ReaderSettings.maxFont,
                  divisions: 15,
                  label: settings.fontSize.round().toString(),
                  onChanged: notifier.setFontSize,
                ),
              ),
              const Text('ا', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          label('تباعد الأسطر'),
          SegmentedButton<ReaderSpacing>(
            segments: [
              for (final s in ReaderSpacing.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {settings.spacing},
            showSelectedIcon: false,
            onSelectionChanged: (s) => notifier.setSpacing(s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          label('لون الصفحة'),
          Row(
            children: [
              for (final t in ReaderTheme.values) ...[
                Expanded(
                  child: _ThemeSwatch(
                    theme: t,
                    selected: t == current,
                    onTap: () => notifier.setTheme(t),
                  ),
                ),
                if (t != ReaderTheme.values.last)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = switch (theme) {
      ReaderTheme.light => _ReaderPalette.light,
      ReaderTheme.sepia => _ReaderPalette.sepia,
      ReaderTheme.dark => _ReaderPalette.night,
    };
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: 'لون الصفحة ${theme.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pal.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color:
                      selected ? colors.brand : Theme.of(context).dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text('أ', style: TextStyle(color: pal.ink, fontSize: 18)),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              theme.label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? colors.brand : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
