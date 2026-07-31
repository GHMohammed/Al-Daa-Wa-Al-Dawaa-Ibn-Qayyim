import 'dart:io';

import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// إدارة تحميل ملفات الدروس محلياً
class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  static const _downloadHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'audio/mpeg,application/octet-stream,*/*',
  };

  static final CacheManager _cacheManager = CacheManager(
    Config(
      'al_daa_lessons',
      stalePeriod: const Duration(days: 3650),
      maxNrOfCacheObjects: 120,
    ),
  );

  final Map<int, DownloadCancelToken> _cancelTokens = {};

  /// هل الرابط من Google Drive؟
  static bool isGoogleDriveUrl(String url) =>
      url.contains('drive.google.com') || url.contains('docs.google.com');

  /// يُوحّد رابط Google Drive إلى صيغة التحميل المباشرة
  static String normalizeDownloadUrl(String url) {
    final fileId = _extractGoogleDriveFileId(url);
    if (fileId != null) {
      // drive.usercontent.google.com مع confirm=t يتجاوز صفحة تأكيد الفيروسات
      return 'https://drive.usercontent.google.com/download?id=$fileId&export=download&authuser=0&confirm=t';
    }
    return url;
  }

  static String? _extractGoogleDriveFileId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final id = uri.queryParameters['id'];
    if (id != null && id.isNotEmpty) return id;

    final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  /// يفتح رابط التحميل في المتصفح الخارجي (بديل عند فشل التحميل داخل التطبيق)
  Future<bool> openInBrowser(String url) async {
    final uri = Uri.parse(normalizeDownloadUrl(url));
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<Directory> _lessonsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'lessons'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _filePathForLesson(int lessonId) => 'lesson_$lessonId.mp3';
  String _cacheKeyForLesson(int lessonId) => 'lesson_$lessonId';

  Future<String> downloadLesson({
    required int lessonId,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _lessonsDirectory();
    final filePath = p.join(dir.path, _filePathForLesson(lessonId));

    final existingPath =
        await DatabaseHelper.instance.getDownloadPath(lessonId);
    if (existingPath != null && await File(existingPath).exists()) {
      debugPrint('[DL] ✅ Already on disk: $existingPath');
      return existingPath;
    }

    final cancelToken = DownloadCancelToken();
    _cancelTokens[lessonId] = cancelToken;

    try {
      final normalizedUrl = normalizeDownloadUrl(url);
      debugPrint('[DL] 🌐 Requesting URL: $normalizedUrl');
      // تنظيف أي ملف مخزّن مؤقتاً فاسد (HTML بدل الملف الصوتي) قبل البدء
      await _cacheManager.removeFile(_cacheKeyForLesson(lessonId));
      final cachedFile = await _downloadViaCacheManager(
        url: normalizedUrl,
        cacheKey: _cacheKeyForLesson(lessonId),
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

      if (!await _isValidAudioFile(cachedFile)) {
        throw Exception(
          'الملف المُحمّل غير صالح (ربما صفحة تأكيد Google Drive)',
        );
      }

      final dest = File(filePath);
      if (await dest.exists()) {
        await dest.delete();
      }
      await cachedFile.copy(dest.path);

      await DatabaseHelper.instance.saveDownload(lessonId, filePath);
      return filePath;
    } finally {
      _cancelTokens.remove(lessonId);
    }
  }

  Future<File> _downloadViaCacheManager({
    required String url,
    required String cacheKey,
    required DownloadCancelToken cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    File? result;

    await for (final response in _cacheManager.getFileStream(
      url,
      key: cacheKey,
      headers: _downloadHeaders,
      withProgress: true,
    )) {
      _throwIfCancelled(cancelToken);

      if (response is DownloadProgress) {
        final value = response.progress;
        debugPrint(
          '[DL] 📊 progress=${value?.toStringAsFixed(2)} '
          'downloaded=${response.downloaded} '
          'total=${response.totalSize}',
        );
        if (value != null && onProgress != null) {
          onProgress(value.clamp(0.0, 1.0));
        }
      } else if (response is FileInfo) {
        final sz = await response.file.length();
        debugPrint('[DL] 📁 FileInfo: ${response.file.path} — $sz bytes');
        result = response.file;
      }
    }

    _throwIfCancelled(cancelToken);

    if (result == null || !await result.exists()) {
      throw Exception('فشل تحميل الملف — لم يُعاد ملف من الذاكرة المؤقتة');
    }

    return result;
  }

  Future<bool> _isValidAudioFile(File file) async {
    if (!await file.exists()) {
      debugPrint('[DL] ❌ isValid: file does not exist');
      return false;
    }

    final length = await file.length();
    debugPrint('[DL] 📦 isValid: file size = $length bytes');
    if (length < 50 * 1024) {
      debugPrint('[DL] ❌ isValid: too small (< 50 KB)');
      return false;
    }

    final raf = await file.open();
    try {
      final header = await raf.read(32);
      final start = String.fromCharCodes(header).toLowerCase();
      debugPrint('[DL] 🔍 isValid: header = "$start"');
      if (start.contains('<!doctype') || start.contains('<html')) {
        debugPrint('[DL] ❌ isValid: HTML content detected!');
        return false;
      }
    } finally {
      await raf.close();
    }

    debugPrint('[DL] ✅ isValid: file looks like audio');
    return true;
  }

  void _throwIfCancelled(DownloadCancelToken cancelToken) {
    if (cancelToken.isCancelled) {
      throw DownloadCancelledException();
    }
  }

  Future<bool> isDownloaded(int lessonId) async {
    final path = await DatabaseHelper.instance.getDownloadPath(lessonId);
    if (path == null) return false;
    return File(path).exists();
  }

  Future<void> deleteLesson(int lessonId) async {
    await cancelDownload(lessonId);
    final path = await DatabaseHelper.instance.getDownloadPath(lessonId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await DatabaseHelper.instance.deleteDownload(lessonId);
    }
    await _cacheManager.removeFile(_cacheKeyForLesson(lessonId));
  }

  Future<double> getStorageUsedMB() async {
    final dir = await _lessonsDirectory();
    if (!await dir.exists()) return 0;

    var totalBytes = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }

  Future<void> cancelDownload(int lessonId) async {
    final token = _cancelTokens[lessonId];
    token?.cancel();
    _cancelTokens.remove(lessonId);

    final dir = await _lessonsDirectory();
    final partial = File(p.join(dir.path, _filePathForLesson(lessonId)));
    if (await partial.exists()) {
      await partial.delete();
    }
  }
}

/// رمز إلغاء التحميل
class DownloadCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class DownloadCancelledException implements Exception {
  @override
  String toString() => 'تم إلغاء التحميل';
}
