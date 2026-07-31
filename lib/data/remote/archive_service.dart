import 'dart:convert';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:flutter/services.dart';

/// تحميل قائمة الدروس من الأصول المحلية
class ArchiveService {
  ArchiveService._();
  static final ArchiveService instance = ArchiveService._();

  List<LessonModel>? _cachedLessons;

  Future<List<LessonModel>> loadLessons() async {
    if (_cachedLessons != null) return _cachedLessons!;

    final jsonString =
        await rootBundle.loadString(AppConstants.lessonsAssetPath);
    final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
    _cachedLessons = decoded
        .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cachedLessons!;
  }

  Future<LessonModel?> getLessonById(int id) async {
    final lessons = await loadLessons();
    try {
      return lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearCache() => _cachedLessons = null;
}
