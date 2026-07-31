import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/download_manager.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// زر تحميل الدرس مع شريط تقدم
class DownloadButton extends ConsumerWidget {
  const DownloadButton({
    super.key,
    required this.lesson,
    this.compact = false,
  });

  final LessonModel lesson;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downloadStatusProvider)[lesson.id] ??
        DownloadStatus.notDownloaded;
    final progress = ref.watch(downloadProgressProvider(lesson.id));

    if (status == DownloadStatus.downloaded) {
      return compact
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : Chip(
              label: const Text('محفوظ'),
              backgroundColor: Colors.green.shade100,
              labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
              visualDensity: VisualDensity.compact,
            );
    }

    if (status == DownloadStatus.downloading) {
      return SizedBox(
        width: compact ? 28 : 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            if (!compact)
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      );
    }

    final sizeMb =
        AppConstants.estimateFileSizeMB(lesson.duration).toStringAsFixed(1);

    if (compact) {
      return IconButton(
        onPressed: () => _startDownload(context, ref),
        icon: const Icon(Icons.download, size: 20),
        tooltip: 'تحميل (~$sizeMb م.ب)',
      );
    }

    return TextButton.icon(
      onPressed: () => _startDownload(context, ref),
      icon: const Icon(Icons.download, size: 20),
      label: Text('~$sizeMb م.ب'),
    );
  }

  Future<void> _startDownload(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(downloadStatusProvider.notifier).downloadLesson(
            lesson,
            (p) {
              ref.read(downloadProgressProvider(lesson.id).notifier).state = p;
            },
          );
      ref.invalidate(storageUsedProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الدرس للاستماع بدون إنترنت')),
      );
    } catch (e) {
      if (!context.mounted) return;

      final isDrive = DownloadManager.isGoogleDriveUrl(lesson.fileUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDrive
                ? 'فشل التحميل داخل التطبيق. يمكنك التحميل عبر المتصفح ثم الاستماع أونلاين.'
                : 'فشل التحميل: $e',
          ),
          duration: const Duration(seconds: 6),
          action: isDrive
              ? SnackBarAction(
                  label: 'المتصفح',
                  onPressed: () => _openInBrowser(context),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _openInBrowser(BuildContext context) async {
    final opened =
        await DownloadManager.instance.openInBrowser(lesson.fileUrl);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المتصفح')),
      );
    }
  }
}
