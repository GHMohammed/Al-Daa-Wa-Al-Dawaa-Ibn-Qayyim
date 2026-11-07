import 'dart:convert';

import 'package:al_daa_wal_dawaa/core/utils/arabic_text.dart';
import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bookAssetPath = 'assets/data/book.json';

BookModel _parse(String raw) =>
    BookModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

/// الكتاب كاملاً — يُحلَّل في Isolate لأن الملف ~0.7 ميغابايت
final bookProvider = FutureProvider<BookModel>((ref) async {
  final raw = await rootBundle.loadString(bookAssetPath);
  return compute(_parse, raw);
});

// ── عناصر القارئ ─────────────────────────────────────────────────────

enum ReaderItemKind { heading, fasl, paragraph, lesson }

/// عنصر واحد في قائمة القارئ المسطّحة
class ReaderItem {
  const ReaderItem.heading(this.section, this.text)
      : kind = ReaderItemKind.heading,
        paragraph = -1,
        lesson = null;
  const ReaderItem.fasl(this.section, this.paragraph)
      : kind = ReaderItemKind.fasl,
        text = 'فصل',
        lesson = null;
  const ReaderItem.paragraph(this.section, this.paragraph, this.text)
      : kind = ReaderItemKind.paragraph,
        lesson = null;
  const ReaderItem.lesson(this.section, this.paragraph, int this.lesson)
      : kind = ReaderItemKind.lesson,
        text = '';

  final ReaderItemKind kind;
  final int section;
  final int paragraph;
  final String text;
  final int? lesson;
}

class ReaderIndex {
  ReaderIndex(this.book) {
    final faslPattern = RegExp(r'^فصل\s*[:.]?$');
    final anchorsAt = <BookPosition, List<int>>{};
    for (final a in book.anchors) {
      anchorsAt
          .putIfAbsent(BookPosition(a.section, a.paragraph), () => [])
          .add(a.lesson);
    }
    var chars = 0;
    for (var s = 0; s < book.sections.length; s++) {
      final section = book.sections[s];
      sectionStart.add(items.length);
      items.add(ReaderItem.heading(s, section.title));
      for (var p = 0; p < section.paragraphs.length; p++) {
        final text = section.paragraphs[p];
        for (final lesson in anchorsAt[BookPosition(s, p)] ?? const <int>[]) {
          items.add(ReaderItem.lesson(s, p, lesson));
        }
        _positionIndex[BookPosition(s, p)] = items.length;
        items.add(
          faslPattern.hasMatch(text)
              ? ReaderItem.fasl(s, p)
              : ReaderItem.paragraph(s, p, text),
        );
        chars += text.length;
      }
      charsBefore.add(chars);
    }
    totalChars = chars;
  }

  final BookModel book;
  final items = <ReaderItem>[];

  /// فهرس أول عنصر (العنوان) لكل قسم
  final sectionStart = <int>[];

  /// عدد الأحرف حتى نهاية كل قسم — لحساب نسبة التقدم
  final charsBefore = <int>[];
  late final int totalChars;
  final _positionIndex = <BookPosition, int>{};

  int indexOf(BookPosition pos) =>
      _positionIndex[pos] ??
      (pos.section < sectionStart.length ? sectionStart[pos.section] : 0);

  BookPosition positionAt(int index) {
    final item = items[index.clamp(0, items.length - 1)];
    return BookPosition(item.section, item.paragraph < 0 ? 0 : item.paragraph);
  }

  /// نسبة التقدم التقريبية في الكتاب (بالأحرف)
  double progressOf(BookPosition pos) {
    if (totalChars == 0) return 0;
    final before = pos.section == 0 ? 0 : charsBefore[pos.section - 1];
    final paras = book.sections[pos.section].paragraphs;
    var inSection = 0;
    for (var p = 0; p < pos.paragraph && p < paras.length; p++) {
      inSection += paras[p].length;
    }
    return ((before + inSection) / totalChars).clamp(0.0, 1.0);
  }

  /// بحث في النص بعد توحيد الهمزات والتشكيل
  List<BookSearchHit> search(String query, {int limit = 100}) {
    final q = normalizeArabic(query.trim());
    if (q.length < 2) return const [];
    final hits = <BookSearchHit>[];
    for (var s = 0; s < book.sections.length; s++) {
      final paras = book.sections[s].paragraphs;
      for (var p = 0; p < paras.length; p++) {
        final norm = normalizeArabic(paras[p]);
        final at = norm.indexOf(q);
        if (at < 0) continue;
        hits.add(
            BookSearchHit(BookPosition(s, p), _snippet(norm, at, q.length)));
        if (hits.length >= limit) return hits;
      }
    }
    return hits;
  }

  static String _snippet(String text, int at, int len) {
    final start = (at - 40).clamp(0, text.length);
    final end = (at + len + 60).clamp(0, text.length);
    return '${start > 0 ? '… ' : ''}${text.substring(start, end)}${end < text.length ? ' …' : ''}';
  }
}

class BookSearchHit {
  const BookSearchHit(this.position, this.snippet);

  final BookPosition position;
  final String snippet;
}

final readerIndexProvider = FutureProvider<ReaderIndex>((ref) async {
  final book = await ref.watch(bookProvider.future);
  return ReaderIndex(book);
});

// ── موضع القراءة ────────────────────────────────────────────────────

final readingPositionProvider =
    StateNotifierProvider<ReadingPositionNotifier, BookPosition?>(
  (ref) => ReadingPositionNotifier(),
);

class ReadingPositionNotifier extends StateNotifier<BookPosition?> {
  ReadingPositionNotifier() : super(null) {
    _load();
  }

  static const _key = 'reading_position';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null || saved.length != 2 || !mounted) return;
    state ??= BookPosition(int.parse(saved[0]), int.parse(saved[1]));
  }

  Future<void> save(BookPosition pos) async {
    if (pos == state) return;
    state = pos;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ['${pos.section}', '${pos.paragraph}']);
  }
}

// ── إعدادات القراءة ─────────────────────────────────────────────────

enum ReaderTheme {
  light('فاتح'),
  sepia('ورقي'),
  dark('داكن');

  const ReaderTheme(this.label);
  final String label;
}

enum ReaderSpacing {
  compact('ضيّق', 1.7),
  normal('متوسط', 2.0),
  wide('واسع', 2.35);

  const ReaderSpacing(this.label, this.height);
  final String label;
  final double height;
}

@immutable
class ReaderSettings {
  const ReaderSettings({
    this.fontSize = 19,
    this.spacing = ReaderSpacing.normal,
    this.theme,
  });

  static const double minFont = 15;
  static const double maxFont = 30;

  final double fontSize;
  final ReaderSpacing spacing;

  /// null = يتبع وضع التطبيق (فاتح/داكن)
  final ReaderTheme? theme;

  ReaderSettings copyWith({
    double? fontSize,
    ReaderSpacing? spacing,
    ReaderTheme? theme,
  }) =>
      ReaderSettings(
        fontSize: fontSize ?? this.fontSize,
        spacing: spacing ?? this.spacing,
        theme: theme ?? this.theme,
      );
}

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
  (ref) => ReaderSettingsNotifier(),
);

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings()) {
    _load();
  }

  static const _font = 'reader_font_size';
  static const _spacing = 'reader_spacing';
  static const _theme = 'reader_theme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final theme = prefs.getString(_theme);
    final spacing = prefs.getString(_spacing);
    state = ReaderSettings(
      fontSize: prefs.getDouble(_font) ?? state.fontSize,
      spacing:
          ReaderSpacing.values.where((s) => s.name == spacing).firstOrNull ??
              state.spacing,
      theme: ReaderTheme.values.where((t) => t.name == theme).firstOrNull,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(
      fontSize: size.clamp(ReaderSettings.minFont, ReaderSettings.maxFont),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_font, state.fontSize);
  }

  Future<void> setSpacing(ReaderSpacing spacing) async {
    state = state.copyWith(spacing: spacing);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spacing, spacing.name);
  }

  Future<void> setTheme(ReaderTheme theme) async {
    state = state.copyWith(theme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_theme, theme.name);
  }
}
