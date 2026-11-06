import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _at(int seconds) => AppConstants.formatSeconds(seconds);

/// يضيف علامة عند الموضع الحالي ويعرض رسالة تتيح تسميتها
Future<void> addBookmarkWithFeedback(
  BuildContext context,
  WidgetRef ref, {
  required int lessonId,
  required Duration position,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await ref
      .read(annotationsProvider.notifier)
      .addBookmark(lessonId, position);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('أُضيفت علامة عند ${_at(saved.position)}'),
        action: SnackBarAction(
          label: 'تسمية',
          onPressed: () {
            if (context.mounted) showBookmarkLabelDialog(context, ref, saved);
          },
        ),
      ),
    );
}

Future<void> showBookmarkLabelDialog(
  BuildContext context,
  WidgetRef ref,
  BookmarkModel bookmark,
) async {
  final controller = TextEditingController(text: bookmark.label);
  final label = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('عنوان العلامة عند ${_at(bookmark.position)}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 80,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'مثال: تعريف الدعاء'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  if (label == null || bookmark.id == null) return;
  await ref
      .read(annotationsProvider.notifier)
      .renameBookmark(bookmark.id!, label);
}

/// محرّر ملاحظة: جديدة عند موضع، أو تعديل ملاحظة موجودة
Future<void> showNoteEditor(
  BuildContext context,
  WidgetRef ref, {
  required int lessonId,
  required Duration position,
  NoteModel? existing,
}) async {
  final controller = TextEditingController(text: existing?.text);
  final seconds = existing?.position ?? position.inSeconds;
  final text = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            existing == null
                ? 'ملاحظة عند ${_at(seconds)}'
                : 'تعديل الملاحظة عند ${_at(seconds)}',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'اكتب ما استفدته من هذا الموضع',
              filled: true,
              fillColor: ctx.colors.accentContainer.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ الملاحظة'),
          ),
        ],
      ),
    ),
  );
  if (text == null || text.trim().isEmpty) return;
  final notifier = ref.read(annotationsProvider.notifier);
  if (existing?.id != null) {
    await notifier.editNote(existing!.id!, text);
  } else {
    await notifier.addNote(lessonId, Duration(seconds: seconds), text);
  }
}

/// يحذف العنصر مع إمكانية التراجع من الرسالة
Future<void> deleteAnnotationWithUndo(
  BuildContext context,
  WidgetRef ref,
  AnnotationItem item,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(annotationsProvider.notifier);
  final removed = await notifier.remove(item);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(item.isNote ? 'حُذفت الملاحظة' : 'حُذفت العلامة'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => notifier.restore(removed),
        ),
      ),
    );
}

/// صف علامة أو ملاحظة — يُستخدم في قائمة المشغّل وشاشة «علاماتي»
class AnnotationTile extends ConsumerWidget {
  const AnnotationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.lessonTitle,
  });

  final AnnotationItem item;
  final VoidCallback onTap;

  /// يُعرض في شاشة «علاماتي» حيث تختلط الدروس
  final String? lessonTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final body = item.text;
    final when = 'عند ${_at(item.position)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg - 2,
          AppSpacing.sm,
          AppSpacing.xxs,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.isNote
                    ? colors.accentContainer
                    : colors.gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isNote ? Icons.edit_note_rounded : Icons.bookmark_rounded,
                size: 19,
                color: item.isNote ? colors.onAccentContainer : colors.gold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lessonTitle != null)
                    Text(
                      'الدرس ${item.lessonId}: $lessonTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                  Text(
                    body?.isNotEmpty == true
                        ? body!
                        : (item.isNote ? 'ملاحظة' : 'علامة بلا عنوان'),
                    maxLines: item.isNote ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: body?.isNotEmpty == true
                          ? null
                          : colors.textSecondary,
                    ),
                  ),
                  Text(
                    when,
                    style: text.labelMedium?.copyWith(
                      color: item.isNote ? colors.brand : colors.gold,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'خيارات',
              icon: Icon(Icons.more_vert_rounded, color: colors.textMuted),
              onSelected: (action) {
                if (action == 'delete') {
                  deleteAnnotationWithUndo(context, ref, item);
                } else if (item.isNote) {
                  showNoteEditor(
                    context,
                    ref,
                    lessonId: item.lessonId,
                    position: Duration(seconds: item.position),
                    existing: item.note,
                  );
                } else {
                  showBookmarkLabelDialog(context, ref, item.bookmark!);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(item.isNote ? 'تعديل' : 'تسمية'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
