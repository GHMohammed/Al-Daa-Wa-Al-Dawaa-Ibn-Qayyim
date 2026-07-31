class ProgressModel {
  final int lessonId;
  final int position;
  final int totalDuration;
  final bool completed;
  final DateTime lastPlayed;

  const ProgressModel({
    required this.lessonId,
    required this.position,
    required this.totalDuration,
    required this.completed,
    required this.lastPlayed,
  });

  double get percentage => totalDuration > 0
      ? (position / totalDuration).clamp(0.0, 1.0)
      : 0.0;

  factory ProgressModel.fromJson(Map<String, dynamic> json) => ProgressModel(
        lessonId: json['lesson_id'] as int,
        position: json['position'] as int,
        totalDuration: json['total_duration'] as int,
        completed: (json['completed'] as int) == 1,
        lastPlayed: DateTime.parse(json['last_played'] as String),
      );

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'position': position,
        'total_duration': totalDuration,
        'completed': completed ? 1 : 0,
        'last_played': lastPlayed.toIso8601String(),
      };

  ProgressModel copyWith({
    int? lessonId,
    int? position,
    int? totalDuration,
    bool? completed,
    DateTime? lastPlayed,
  }) {
    return ProgressModel(
      lessonId: lessonId ?? this.lessonId,
      position: position ?? this.position,
      totalDuration: totalDuration ?? this.totalDuration,
      completed: completed ?? this.completed,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}
