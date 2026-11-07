import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_format.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_service.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/book_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/listening_stats.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/settings_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// شاشة الإعدادات
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // لا نحدد backgroundColor — الـ Scaffold يأخذها من scaffoldBackgroundColor
    // في الثيم (AppTheme)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              PageHeader(title: 'الإعدادات'),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── القسم الأول: الكتاب ──────────────────────────
                    _SectionLabel(label: 'الكتاب'),
                    SizedBox(height: 8),
                    _BookCard(),
                    SizedBox(height: 24),
                    // ── الاستماع والمظهر ──────────────────────────────
                    _SectionLabel(label: 'الاستماع والمظهر'),
                    SizedBox(height: 8),
                    _PreferencesCard(),
                    SizedBox(height: 24),
                    // ── القسم الثاني: إدارة التخزين ──────────────────
                    _SectionLabel(label: 'إدارة التخزين'),
                    SizedBox(height: 8),
                    _StorageCard(),
                    SizedBox(height: 24),
                    // ── النسخ الاحتياطي ───────────────────────────────
                    _SectionLabel(label: 'النسخ الاحتياطي'),
                    SizedBox(height: 8),
                    _BackupCard(),
                    SizedBox(height: 24),
                    // ── عن التطبيق ────────────────────────────────────
                    _SectionLabel(label: 'عن التطبيق'),
                    SizedBox(height: 8),
                    _AboutCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// مكوّنات مشتركة
// ─────────────────────────────────────────────────────────────────────────────

/// عنوان القسم الصغير فوق البطاقة
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: AppTypography.medium,
          // فاتح: رمادي متوسط  |  داكن: أبيض شفاف 50%
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// بطاقة بزوايا دائرية — الحاوية المشتركة لكل قسم
/// اللون من cardTheme في الثيم
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            // الظل مرئي فقط في الوضع الفاتح
            color: isDark
                ? Colors.transparent
                : context.colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// مربع أيقونة بخلفية هادئة من لون الهوية
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.size = 44});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.accentContainer,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child:
          Icon(icon, color: context.colors.onAccentContainer, size: size * 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة الكتاب
// ─────────────────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  const _BookCard();

  @override
  Widget build(BuildContext context) {
    // النص الثانوي (اسم الشيخ) — شفاف 60% من onSurface
    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return _SettingsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconBox(icon: Icons.menu_book_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'شرح كتاب الداء والدواء لابن القيم الجوزية',
                  style: TextStyle(
                    fontWeight: AppTypography.medium,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'شرح الشيخ عبد الرزاق بن عبد المحسن البدر',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppConstants.totalLessons} درساً مفهرساً',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.accent,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة الاستماع والمظهر
// ─────────────────────────────────────────────────────────────────────────────

class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final mutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.skip_next_rounded, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تشغيل الدرس التالي تلقائياً',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'عند انتهاء الدرس الحالي',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.autoplayNext,
                onChanged: notifier.setAutoplayNext,
              ),
            ],
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          const Row(
            children: [
              _IconBox(icon: Icons.contrast_rounded, size: 36),
              SizedBox(width: 12),
              Text('المظهر', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('حسب الجهاز')),
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
              ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => notifier.setThemeMode(s.first),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة إدارة التخزين
// ─────────────────────────────────────────────────────────────────────────────

class _StorageCard extends ConsumerWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageUsedProvider);
    final statuses = ref.watch(downloadStatusProvider);
    final downloadedCount =
        statuses.values.where((s) => s == DownloadStatus.downloaded).length;

    final storageMb = storageAsync.maybeWhen(
      data: (mb) => '${mb.toStringAsFixed(1)} MB',
      orElse: () => '...',
    );

    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    // لون الـ progress track: شفاف 12% من onSurface
    final trackColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    // لون الأزرار المعطّلة من الثيم
    final disabledColor = Theme.of(context).disabledColor;
    final colors = context.colors;

    // ── حذف كل الدروس بعد تأكيد AlertDialog
    Future<void> deleteAll() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('مسح جميع الدروس'),
          content: const Text(
            'هل أنت متأكد من حذف جميع الدروس المحمّلة؟\n'
            'لا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: const Text('مسح الكل'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      final notifier = ref.read(downloadStatusProvider.notifier);
      final ids = statuses.entries
          .where((e) => e.value == DownloadStatus.downloaded)
          .map((e) => e.key)
          .toList();
      for (final id in ids) {
        await notifier.deleteLesson(id);
      }
      ref.invalidate(storageUsedProvider);
    }

    // ── فتح Bottom Sheet إدارة الدروس
    void showManageSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ManageLessonsSheet(),
      );
    }

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان + badge حجم التخزين (ألوان badge ثابتة — هوية التطبيق)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المساحة المستخدمة',
                style:
                    TextStyle(fontWeight: AppTypography.medium, fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  storageMb,
                  style: TextStyle(
                    color: colors.onAccentContainer,
                    fontSize: 12,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شريط التقدم — track color من الثيم
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:
                  (downloadedCount / AppConstants.totalLessons).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الدروس المحمّلة: $downloadedCount من ${AppConstants.totalLessons} درس',
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
          const SizedBox(height: 16),
          // زرا الإجراء
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: showManageSheet,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('إدارة الدروس'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.brand,
                    side: BorderSide(color: colors.brand, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: downloadedCount == 0 ? null : deleteAll,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('مسح الكل'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(color: colors.danger, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // لون الزر المعطّل من الثيم
                    disabledForegroundColor: disabledColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet — قائمة الدروس المحمّلة مع إمكانية الحذف المنفرد
// ─────────────────────────────────────────────────────────────────────────────

class _ManageLessonsSheet extends ConsumerWidget {
  const _ManageLessonsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(downloadStatusProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    final downloadedLessons = lessonsAsync.maybeWhen(
      data: (lessons) => lessons
          .where((l) => statuses[l.lesson.id] == DownloadStatus.downloaded)
          .toList(),
      orElse: () => <LessonWithProgress>[],
    );

    // ألوان الثيم المستخدمة داخل الـ sheet
    final sheetBg = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    final handleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    final emptyIconColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    final emptyTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // العنوان + عداد الدروس
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الدروس المحمّلة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.medium,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${downloadedLessons.length} درس',
                    style: TextStyle(
                      color: colors.onAccentContainer,
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // المحتوى: قائمة أو حالة الفراغ
          Flexible(
            child: downloadedLessons.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_done_rounded,
                          size: 52,
                          color: emptyIconColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد دروس محمّلة',
                          style: TextStyle(
                            color: emptyTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: downloadedLessons.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 60),
                    itemBuilder: (_, i) {
                      final item = downloadedLessons[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.accentContainer,
                          foregroundColor: colors.onAccentContainer,
                          radius: 18,
                          child: Text(
                            '${item.lesson.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ),
                        title: Text(
                          item.lesson.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          AppConstants.formatSeconds(item.lesson.duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: subtitleColor,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.danger,
                            size: 22,
                          ),
                          onPressed: () async {
                            await ref
                                .read(downloadStatusProvider.notifier)
                                .deleteLesson(item.lesson.id);
                            ref.invalidate(storageUsedProvider);
                          },
                        ),
                      );
                    },
                  ),
          ),
          // مسافة أمان سفلية (home indicator على iOS)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة النسخ الاحتياطي — التلقائي (أندرويد) واليدوي (تصدير/استعادة)
// ─────────────────────────────────────────────────────────────────────────────

class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard();

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final file = await BackupService.export();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          text: 'نسخة احتياطية — شرح كتاب الداء والدواء',
        ),
      );
      // أندرويد لا يخبر دائماً بما اختاره المستخدم؛ نعدّها نسخة ما لم يُلغِ
      if (result.status != ShareResultStatus.dismissed) {
        await ref.read(sharedPrefsProvider).setString(
              BackupService.lastExportKey,
              DateTime.now().toIso8601String(),
            );
      }
    } catch (_) {
      _snack('تعذّر إنشاء النسخة الاحتياطية');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final preview = BackupService.read(await picked.readAsBytes());
      if (!mounted) return;
      final confirmed = await _confirm(preview.manifest);
      if (confirmed != true) return;

      final result = await BackupService.restore(preview);
      // الشاشات تقرأ من قاعدة البيانات من جديد دون إعادة تشغيل التطبيق
      ref
        ..invalidate(progressMapProvider)
        ..invalidate(listeningLogProvider)
        ..invalidate(annotationsProvider)
        ..invalidate(readingPositionProvider)
        ..invalidate(lessonsProvider);
      _snack(_resultMessage(result));
    } on BackupException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('تعذّرت الاستعادة، ولم يتغيّر شيء من بياناتك');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm(BackupManifest m) {
    final d = m.createdAt;
    final voice = m.voiceNotes > 0 ? ' (منها ${m.voiceNotes} صوتية)' : '';
    final lines = [
      'نسخة بتاريخ ${d.day}/${d.month}/${d.year}',
      _count(
        m.completedLessons,
        const [
          'لا دروس مكتملة',
          'درس واحد مكتمل',
          'درسان مكتملان',
          'دروس مكتملة',
          'درساً مكتملاً',
        ],
      ),
      _count(m.bookmarks, _bookmarkForms),
      '${_count(m.notes, _noteForms)}$voice',
    ];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة النسخة'),
        content: Text(
          '${lines.join('\n')}\n\n'
          'تُضاف هذه البيانات إلى الموجودة دون حذف شيء.',
          style: const TextStyle(height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  static String _resultMessage(BackupMergeResult r) {
    if (r.isEmpty) return 'بياناتك تحتوي كل ما في النسخة، لا شيء جديد';
    final parts = [
      if (r.progressUpdated > 0)
        'تقدم ${_count(r.progressUpdated, const [
              '',
              'درس واحد',
              'درسين',
              'دروس',
              'درساً'
            ])}',
      if (r.bookmarksAdded > 0) _count(r.bookmarksAdded, _bookmarkForms),
      if (r.notesAdded > 0) _count(r.notesAdded, _noteForms),
      if (r.daysUpdated > 0)
        'سجل ${_count(r.daysUpdated, const [
              '',
              'يوم واحد',
              'يومين',
              'أيام',
              'يوماً'
            ])}',
    ];
    return 'تمت الاستعادة: ${parts.join('، ')}';
  }

  static const _bookmarkForms = [
    'لا علامات',
    'علامة واحدة',
    'علامتان',
    'علامات',
    'علامة',
  ];
  static const _noteForms = [
    'لا ملاحظات',
    'ملاحظة واحدة',
    'ملاحظتان',
    'ملاحظات',
    'ملاحظة',
  ];

  /// تمييز العدد بالعربية. [forms]: صفر، واحد، مثنى، جمع (3–10)،
  /// مفرد منصوب (11 فما فوق)
  static String _count(int n, List<String> forms) => switch (n) {
        0 => forms[0],
        1 => forms[1],
        2 => forms[2],
        <= 10 => '$n ${forms[3]}',
        _ => '$n ${forms[4]}',
      };

  String _lastExportText() {
    final saved =
        ref.read(sharedPrefsProvider).getString(BackupService.lastExportKey);
    final at = saved == null ? null : DateTime.tryParse(saved);
    if (at == null) return 'لم تُصدِّر نسخة بعد';
    final days = DateTime.now().difference(at).inDays;
    return switch (days) {
      0 => 'آخر نسخة: اليوم',
      1 => 'آخر نسخة: أمس',
      2 => 'آخر نسخة: قبل يومين',
      <= 10 => 'آخر نسخة: قبل $days أيام',
      _ => 'آخر نسخة: قبل $days يوماً',
    };
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final colors = context.colors;
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: colors.brand,
      side: BorderSide(color: colors.brand, width: 1),
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final descStyle = TextStyle(fontSize: 12, color: mutedColor, height: 1.5);

    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النسخ التلقائي في أندرويد (docs/auto-backup-plan.md)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBox(icon: Icons.cloud_done_outlined, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تلقائي', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'يُحفظ تقدمك وعلاماتك وملاحظاتك في نسخة هاتفك '
                      'الاحتياطية على حساب Google، وتعود عند إعادة التثبيت '
                      'أو على هاتف جديد.',
                      style: descStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          // التصدير والاستيراد اليدوي (docs/manual-backup-plan.md)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBox(icon: Icons.save_alt_rounded, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نسخة يدوية', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'احفظ بياناتك في ملف تضعه حيث تشاء، كالرسائل '
                      'المحفوظة في تلغرام، واستعدها متى احتجت.',
                      style: descStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastExportText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.accent,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('تصدير نسخة'),
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _import,
                    icon: const Icon(
                      Icons.settings_backup_restore_rounded,
                      size: 18,
                    ),
                    label: const Text('استعادة نسخة'),
                    style: buttonStyle,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة عن التطبيق
// ─────────────────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  Future<void> _openDevLink() async {
    final uri = Uri.parse('https://www.mohammednour.dev/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final iconMutedColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return _SettingsCard(
      child: Column(
        children: [
          // صف الإصدار
          Row(
            children: [
              const _IconBox(icon: Icons.info_outline_rounded, size: 36),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('الإصدار', style: TextStyle(fontSize: 14)),
              ),
              Text(
                AppConstants.appVersion,
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // الفاصل من الثيم
          Divider(height: 24, color: Theme.of(context).dividerColor),
          // صف المطور — قابل للنقر لفتح الموقع
          InkWell(
            onTap: _openDevLink,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const _IconBox(icon: Icons.code_rounded, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم التطوير بواسطة',
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'م. محمد نور الدين',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: iconMutedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
