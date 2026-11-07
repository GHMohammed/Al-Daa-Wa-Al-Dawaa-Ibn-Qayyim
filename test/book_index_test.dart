import 'dart:convert';
import 'dart:io';

import 'package:al_daa_wal_dawaa/core/utils/arabic_text.dart';
import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/book_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ReaderIndex index;

  setUpAll(() {
    final raw = File('assets/data/book.json').readAsStringSync();
    index = ReaderIndex(
      BookModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );
  });

  test('book asset is complete and well-formed', () {
    final book = index.book;
    expect(book.sections.length, greaterThan(80));
    expect(book.sections.first.paragraphs, isNotEmpty);
    expect(book.anchors.length, greaterThan(60));
    // نهاية الكتاب الحقيقية
    expect(book.sections.last.paragraphs.last, contains('آثر حبّه على هواه'));
    // لا أرقام حواشٍ ولا وسوم HTML
    final all = book.sections.expand((s) => s.paragraphs).join('\n');
    expect(all.contains('<'), isFalse);
  });

  test('every lesson anchor points at a real paragraph', () {
    for (final a in index.book.anchors) {
      final s = index.book.sections[a.section];
      expect(a.paragraph, lessThan(s.paragraphs.length));
      final i = index.indexOf(BookPosition(a.section, a.paragraph));
      // عنصر الدرس يسبق فقرته مباشرة
      expect(
        index.items.sublist(0, i).reversed.take(5).any(
              (it) => it.kind == ReaderItemKind.lesson && it.lesson == a.lesson,
            ),
        isTrue,
      );
    }
  });

  test('position round-trip and progress bounds', () {
    const pos = BookPosition(10, 3);
    final i = index.indexOf(pos);
    expect(index.positionAt(i), pos);
    expect(index.progressOf(const BookPosition(0, 0)), 0);
    expect(index.progressOf(pos), inExclusiveRange(0, 1));
  });

  test('search ignores diacritics and hamza forms', () {
    expect(normalizeArabic('الدُّعَاءُ أنفع'), 'الدعاء انفع');
    final hits = index.search('الدعاء من انفع الادوية');
    expect(hits, isNotEmpty);
  });
}
