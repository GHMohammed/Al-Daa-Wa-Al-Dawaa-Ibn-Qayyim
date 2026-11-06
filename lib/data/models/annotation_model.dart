/// علامة مرجعية عند موضع في درس
class BookmarkModel {
  const BookmarkModel({
    this.id,
    required this.lessonId,
    required this.position,
    this.label,
    required this.createdAt,
  });

  final int? id;
  final int lessonId;

  /// الموضع بالثواني
  final int position;
  final String? label;
  final DateTime createdAt;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) => BookmarkModel(
        id: json['id'] as int?,
        lessonId: json['lesson_id'] as int,
        position: json['position'] as int,
        label: json['label'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'lesson_id': lessonId,
        'position': position,
        'label': label,
        'created_at': createdAt.toIso8601String(),
      };

  BookmarkModel copyWith({int? id, String? label}) => BookmarkModel(
        id: id ?? this.id,
        lessonId: lessonId,
        position: position,
        label: label ?? this.label,
        createdAt: createdAt,
      );
}

/// ملاحظة مرتبطة بموضع في درس — نصية الآن، وصوتية لاحقاً (audioPath)
class NoteModel {
  const NoteModel({
    this.id,
    required this.lessonId,
    required this.position,
    this.text,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int lessonId;

  /// الموضع بالثواني
  final int position;
  final String? text;
  final String? audioPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as int?,
        lessonId: json['lesson_id'] as int,
        position: json['position'] as int,
        text: json['text'] as String?,
        audioPath: json['audio_path'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'lesson_id': lessonId,
        'position': position,
        'text': text,
        'audio_path': audioPath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NoteModel copyWith({int? id, String? text, DateTime? updatedAt}) => NoteModel(
        id: id ?? this.id,
        lessonId: lessonId,
        position: position,
        text: text ?? this.text,
        audioPath: audioPath,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
