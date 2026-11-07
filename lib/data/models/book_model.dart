/// نص الكتاب: طبعة عطاءات العلم (تحقيق الإصلاحي) — المتن دون الحواشي
class BookModel {
  const BookModel({
    required this.title,
    required this.author,
    required this.edition,
    required this.source,
    required this.sections,
    required this.anchors,
  });

  final String title;
  final String author;
  final String edition;
  final String source;
  final List<BookSection> sections;

  /// مواضع بدء شرح الدروس في النص
  final List<LessonAnchor> anchors;

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
        title: json['title'] as String,
        author: json['author'] as String,
        edition: json['edition'] as String,
        source: json['source'] as String,
        sections: [
          for (final s in json['sections'] as List)
            BookSection.fromJson(s as Map<String, dynamic>),
        ],
        anchors: [
          for (final a in json['anchors'] as List)
            LessonAnchor.fromJson(a as Map<String, dynamic>),
        ],
      );

  LessonAnchor? anchorForLesson(int lessonId) {
    for (final a in anchors) {
      if (a.lesson == lessonId) return a;
    }
    return null;
  }

  /// الدروس التي يبدأ شرحها داخل قسم معيّن
  List<int> lessonsInSection(int section) => [
        for (final a in anchors)
          if (a.section == section) a.lesson,
      ];
}

class BookSection {
  const BookSection({
    required this.title,
    required this.page,
    required this.paragraphs,
  });

  /// عنوان المحقق (للفهرس)
  final String title;

  /// رقم الصفحة في الطبعة المطبوعة
  final int page;
  final List<String> paragraphs;

  factory BookSection.fromJson(Map<String, dynamic> json) => BookSection(
        title: json['title'] as String,
        page: json['page'] as int,
        paragraphs: [for (final p in json['paragraphs'] as List) p as String],
      );
}

class LessonAnchor {
  const LessonAnchor({
    required this.lesson,
    required this.section,
    required this.paragraph,
  });

  final int lesson;
  final int section;
  final int paragraph;

  factory LessonAnchor.fromJson(Map<String, dynamic> json) => LessonAnchor(
        lesson: json['lesson'] as int,
        section: json['section'] as int,
        paragraph: json['paragraph'] as int,
      );
}

/// موضع في الكتاب (قسم + فقرة)
class BookPosition {
  const BookPosition(this.section, this.paragraph);

  final int section;
  final int paragraph;

  @override
  bool operator ==(Object other) =>
      other is BookPosition &&
      other.section == section &&
      other.paragraph == paragraph;

  @override
  int get hashCode => Object.hash(section, paragraph);
}
