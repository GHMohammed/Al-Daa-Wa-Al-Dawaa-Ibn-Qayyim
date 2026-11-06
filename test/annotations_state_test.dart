import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 7, 10);
  final state = AnnotationsState(
    bookmarks: [
      BookmarkModel(id: 1, lessonId: 3, position: 900, createdAt: t0),
      BookmarkModel(
        id: 2,
        lessonId: 5,
        position: 60,
        label: 'تعريف الدعاء',
        createdAt: t0.add(const Duration(minutes: 5)),
      ),
    ],
    notes: [
      NoteModel(
        id: 1,
        lessonId: 3,
        position: 120,
        text: 'فائدة',
        createdAt: t0.add(const Duration(minutes: 2)),
        updatedAt: t0.add(const Duration(minutes: 2)),
      ),
    ],
  );

  test('forLesson returns only that lesson, ordered by audio position', () {
    final items = state.forLesson(3);
    expect(items.map((i) => i.position), [120, 900]);
    expect(items.first.isNote, isTrue);
    expect(items.last.text, isNull);
  });

  test('all mixes bookmarks and notes, newest first', () {
    expect(state.all.map((i) => i.lessonId), [5, 3, 3]);
    expect(state.all.first.text, 'تعريف الدعاء');
  });

  test('voice notes are notes with an audio path and no text', () {
    final voice = AnnotationItem.note(
      NoteModel(
        lessonId: 3,
        position: 30,
        audioPath: '/notes/a.m4a',
        createdAt: t0,
        updatedAt: t0,
      ),
    );
    expect(voice.isNote, isTrue);
    expect(voice.isVoice, isTrue);
    expect(voice.text, isNull);
    expect(state.forLesson(3).any((i) => i.isVoice), isFalse);
  });

  test('bookmark json round-trip keeps label and omits null id', () {
    final b = BookmarkModel(lessonId: 1, position: 10, createdAt: t0);
    expect(b.toJson().containsKey('id'), isFalse);
    final back = BookmarkModel.fromJson({...b.toJson(), 'id': 9});
    expect(back.id, 9);
    expect(back.position, 10);
  });
}
