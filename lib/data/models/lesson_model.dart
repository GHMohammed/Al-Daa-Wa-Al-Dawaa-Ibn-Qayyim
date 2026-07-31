class LessonModel {
  final int id;
  final String title;
  final int duration;
  final String fileUrl;

  const LessonModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.fileUrl,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] as int,
        title: json['title'] as String,
        duration: json['duration'] as int,
        fileUrl: json['fileUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration': duration,
        'fileUrl': fileUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
