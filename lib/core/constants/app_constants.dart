/// ثوابت التطبيق العامة
class AppConstants {
  AppConstants._();

  static const String lessonsAssetPath = 'assets/data/lessons.json';
  static const String coverImagePath = 'assets/images/cover.png';

  static const String appTitle = 'شرح كتاب الداء والدواء';
  static const String sheikhName = 'عبد الرزاق بن عبد المحسن البدر';

  /// إصدار التطبيق الحالي — يجب أن يتطابق مع version في pubspec.yaml
  static const String appVersion = '1.0.0';

  /// رابط ملف version.json على الإنترنت (Google Drive أو GitHub Raw أو غيره)
  /// ضع الرابط المباشر بعد رفع الملف
  static const String updateCheckUrl =
      'https://drive.google.com/uc?export=download&id=1NPJhYIEa_tIHlPEeBguKRSFywmKKngil';

  static const int totalLessons = 83;
  static const double completionThreshold = 0.9;
  static const int positionSaveIntervalSeconds = 5;
  static const int skipSeconds = 30;

  static const List<double> playbackSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  static const String dbName = 'al_daa_wal_dawaa.db';
  static const int dbVersion = 1;

  static const String tableProgress = 'progress';
  static const String tableDownloads = 'downloads';

  static const String androidNotificationChannelId =
      'com.example.al_daa_wal_dawaa.audio';
  static const String androidNotificationChannelName = 'الداء والدواء';

  /// تقدير حجم الملف بالميغابايت (معدل ~96 كيلوبت/ثانية لملفات MP3 شرح)
  static double estimateFileSizeMB(int durationSeconds) {
    const bytesPerSecond = 96 * 1024 / 8;
    return (durationSeconds * bytesPerSecond) / (1024 * 1024);
  }

  /// تنسيق المدة للعرض (م:ث أو س:د:ث)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final sec = seconds.toString().padLeft(2, '0');
    final min = minutes.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$min:$sec';
    }
    return '$min:$sec';
  }

  /// تنسيق المدة من ثوانٍ
  static String formatSeconds(int totalSeconds) {
    return formatDuration(Duration(seconds: totalSeconds));
  }

  /// هل الدرس مكتمل بنسبة 90% فأكثر؟
  static bool isLessonCompleted(int position, int totalDuration) {
    if (totalDuration <= 0) return false;
    return position / totalDuration >= completionThreshold;
  }
}
