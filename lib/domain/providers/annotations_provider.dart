import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// عنصر موحّد لعرض العلامات والملاحظات معاً في القوائم
class AnnotationItem {
  const AnnotationItem.bookmark(BookmarkModel this.bookmark) : note = null;
  const AnnotationItem.note(NoteModel this.note) : bookmark = null;

  final BookmarkModel? bookmark;
  final NoteModel? note;

  bool get isNote => note != null;
  int get lessonId => bookmark?.lessonId ?? note!.lessonId;
  int get position => bookmark?.position ?? note!.position;
  DateTime get createdAt => bookmark?.createdAt ?? note!.createdAt;

  /// عنوان العلامة أو نص الملاحظة (قد يكون فارغاً لعلامة بلا عنوان)
  String? get text => bookmark?.label ?? note?.text;
}

class AnnotationsState {
  const AnnotationsState({this.bookmarks = const [], this.notes = const []});

  final List<BookmarkModel> bookmarks;
  final List<NoteModel> notes;

  /// الكل مرتباً من الأحدث
  List<AnnotationItem> get all => [
        ...bookmarks.map(AnnotationItem.bookmark),
        ...notes.map(AnnotationItem.note),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// عناصر درس واحد مرتبة حسب الموضع في الصوت
  List<AnnotationItem> forLesson(int lessonId) => [
        ...bookmarks
            .where((b) => b.lessonId == lessonId)
            .map(AnnotationItem.bookmark),
        ...notes.where((n) => n.lessonId == lessonId).map(AnnotationItem.note),
      ]..sort((a, b) => a.position.compareTo(b.position));
}

final annotationsProvider =
    StateNotifierProvider<AnnotationsNotifier, AnnotationsState>(
  (ref) => AnnotationsNotifier(),
);

/// عناصر الدرس الحالي — للمشغّل (النقاط على الشريط وقائمة الدرس)
final lessonAnnotationsProvider =
    Provider.family<List<AnnotationItem>, int>((ref, lessonId) {
  return ref.watch(annotationsProvider).forLesson(lessonId);
});

class AnnotationsNotifier extends StateNotifier<AnnotationsState> {
  AnnotationsNotifier() : super(const AnnotationsState()) {
    _load();
  }

  final _db = DatabaseHelper.instance;

  Future<void> _load() async {
    final bookmarks = await _db.getAllBookmarks();
    final notes = await _db.getAllNotes();
    if (!mounted) return;
    state = AnnotationsState(
      bookmarks: [...state.bookmarks, ...bookmarks],
      notes: [...state.notes, ...notes],
    );
  }

  Future<BookmarkModel> addBookmark(int lessonId, Duration position) async {
    final saved = await _db.insertBookmark(
      BookmarkModel(
        lessonId: lessonId,
        position: position.inSeconds,
        createdAt: DateTime.now(),
      ),
    );
    state = AnnotationsState(
      bookmarks: [saved, ...state.bookmarks],
      notes: state.notes,
    );
    return saved;
  }

  Future<void> renameBookmark(int id, String label) async {
    final value = label.trim().isEmpty ? null : label.trim();
    await _db.updateBookmarkLabel(id, value);
    state = AnnotationsState(
      bookmarks: [
        for (final b in state.bookmarks)
          if (b.id == id)
            BookmarkModel(
              id: b.id,
              lessonId: b.lessonId,
              position: b.position,
              label: value,
              createdAt: b.createdAt,
            )
          else
            b,
      ],
      notes: state.notes,
    );
  }

  Future<void> addNote(int lessonId, Duration position, String text) async {
    final now = DateTime.now();
    final saved = await _db.insertNote(
      NoteModel(
        lessonId: lessonId,
        position: position.inSeconds,
        text: text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    state = AnnotationsState(
      bookmarks: state.bookmarks,
      notes: [saved, ...state.notes],
    );
  }

  Future<void> editNote(int id, String text) async {
    final now = DateTime.now();
    await _db.updateNoteText(id, text.trim(), now);
    state = AnnotationsState(
      bookmarks: state.bookmarks,
      notes: [
        for (final n in state.notes)
          if (n.id == id) n.copyWith(text: text.trim(), updatedAt: now) else n,
      ],
    );
  }

  /// يحذف العنصر ويُعيده كما كان — لإتاحة «تراجع» بعد الحذف
  Future<AnnotationItem> remove(AnnotationItem item) async {
    if (item.isNote) {
      await _db.deleteNote(item.note!.id!);
      state = AnnotationsState(
        bookmarks: state.bookmarks,
        notes: state.notes.where((n) => n.id != item.note!.id).toList(),
      );
    } else {
      await _db.deleteBookmark(item.bookmark!.id!);
      state = AnnotationsState(
        bookmarks:
            state.bookmarks.where((b) => b.id != item.bookmark!.id).toList(),
        notes: state.notes,
      );
    }
    return item;
  }

  /// يعيد عنصراً محذوفاً (بمعرّف جديد)
  Future<void> restore(AnnotationItem item) async {
    if (item.isNote) {
      final saved = await _db.insertNote(item.note!);
      state = AnnotationsState(
        bookmarks: state.bookmarks,
        notes: [saved, ...state.notes],
      );
    } else {
      final saved = await _db.insertBookmark(item.bookmark!);
      state = AnnotationsState(
        bookmarks: [saved, ...state.bookmarks],
        notes: state.notes,
      );
    }
  }
}
