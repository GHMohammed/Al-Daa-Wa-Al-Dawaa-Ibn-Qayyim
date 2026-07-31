import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// شاشة الإعدادات
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // لا نحدد backgroundColor — الـ Scaffold يأخذها من scaffoldBackgroundColor
    // في الثيم (فاتح: 0xFFF2F2F7 | داكن: 0xFF121212)
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          // ── القسم الأول: الكتاب ──────────────────────────────
          _SectionLabel(label: 'الكتاب'),
          SizedBox(height: 8),
          _BookCard(),
          SizedBox(height: 24),
          // ── القسم الثاني: إدارة التخزين ──────────────────────
          _SectionLabel(label: 'إدارة التخزين'),
          SizedBox(height: 8),
          _StorageCard(),
          SizedBox(height: 24),
          // ── القسم الثالث: عن التطبيق ─────────────────────────
          _SectionLabel(label: 'عن التطبيق'),
          SizedBox(height: 8),
          _AboutCard(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
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
          fontWeight: FontWeight.w600,
          // فاتح: رمادي متوسط  |  داكن: أبيض شفاف 50%
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// بطاقة بزوايا دائرية — الحاوية المشتركة لكل قسم
/// اللون من cardTheme:  فاتح → Colors.white  |  داكن → Color(0xFF1E1E1E)
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // cardTheme.color: Colors.white (فاتح) أو AppColors.darkSurface (داكن)
    final cardColor =
        Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        // dividerColor: 0xFFEEEEEE (فاتح) | 0xFF2A2A2A (داكن)
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            // الظل مرئي فقط في الوضع الفاتح
            color: isDark
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// مربع أيقونة ملوّن بالأخضر الفاتح — ألوان ثابتة (هوية بصرية)
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
        color: AppColors.lightSurface, // 0xFFE1F5EE — ثابت (هوية التطبيق)
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.5),
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
                    fontWeight: FontWeight.bold,
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
                // اللون الأخضر ثابت — هوية التطبيق
                const Text(
                  '${AppConstants.totalLessons} درساً مفهرساً',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  storageMb,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
              value: (downloadedCount / AppConstants.totalLessons)
                  .clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1),
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
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1),
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
    final sheetBg =
        Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final handleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    final emptyIconColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    final emptyTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final subtitleColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        // cardTheme.color: Colors.white (فاتح) | 0xFF1E1E1E (داكن)
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
          // العنوان + عداد الدروس (badge بألوان هوية التطبيق — ثابتة)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الدروس المحمّلة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${downloadedLessons.length} درس',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                    itemCount: downloadedLessons.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 60),
                    itemBuilder: (_, i) {
                      final item = downloadedLessons[i];
                      return ListTile(
                        leading: CircleAvatar(
                          // دائرة الرقم: ألوان هوية التطبيق — ثابتة
                          backgroundColor: AppColors.lightSurface,
                          foregroundColor: AppColors.primary,
                          radius: 18,
                          child: Text(
                            '${item.lesson.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
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
                '1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // الفاصل من الثيم (0xFFEEEEEE فاتح | 0xFF2A2A2A داكن)
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
                          fontWeight: FontWeight.w600,
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
