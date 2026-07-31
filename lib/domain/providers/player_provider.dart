import 'dart:async';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/data/remote/archive_service.dart';
import 'package:al_daa_wal_dawaa/data/services/app_audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlayerStatus { idle, loading, playing, paused, error }

class PlayerState {
  final LessonModel? currentLesson;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? errorMessage;

  const PlayerState({
    this.currentLesson,
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.errorMessage,
  });

  bool get hasActiveLesson => currentLesson != null;

  PlayerState copyWith({
    LessonModel? currentLesson,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? speed,
    String? errorMessage,
  }) {
    return PlayerState(
      currentLesson: currentLesson ?? this.currentLesson,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      errorMessage: errorMessage,
    );
  }
}

/// يُعيَّن من main بعد AudioService.init
final audioHandlerProvider = Provider<AppAudioHandler>(
  (ref) => throw UnimplementedError(
    'يجب تهيئة audioHandlerProvider من main عبر override',
  ),
);

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier(this._ref) : super(const PlayerState()) {
    _handler = _ref.read(audioHandlerProvider);
    _initListeners();
  }

  final Ref _ref;
  late final AppAudioHandler _handler;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _playbackSub;
  Timer? _saveTimer;
  DateTime _lastSave = DateTime.now();

  void _initListeners() {
    _positionSub = _handler.player.positionStream.listen((position) {
      final duration = _handler.player.duration ?? state.duration;
      state = state.copyWith(
        position: position,
        duration: duration,
        status: _handler.player.playing
            ? PlayerStatus.playing
            : PlayerStatus.paused,
      );
      _maybeSaveProgress();
    });

    _playbackSub = _handler.playbackState.listen((playbackState) {
      if (state.currentLesson == null) return;
      final playing = playbackState.playing;
      state = state.copyWith(
        status: playing ? PlayerStatus.playing : PlayerStatus.paused,
        position: playbackState.updatePosition,
      );
    });
  }

  void _maybeSaveProgress() {
    final now = DateTime.now();
    if (now.difference(_lastSave).inSeconds >=
        AppConstants.positionSaveIntervalSeconds) {
      _lastSave = now;
      _saveCurrentProgress();
    }
  }

  Future<void> _saveCurrentProgress() async {
    final lesson = state.currentLesson;
    if (lesson == null) return;

    final position = state.position.inSeconds;
    final total = state.duration.inSeconds > 0
        ? state.duration.inSeconds
        : lesson.duration;
    final completed = AppConstants.isLessonCompleted(position, total);

    await DatabaseHelper.instance.saveProgress(
      ProgressModel(
        lessonId: lesson.id,
        position: position,
        totalDuration: total,
        completed: completed,
        lastPlayed: DateTime.now(),
      ),
    );
    // لا نستدعي _ref.invalidate(lessonsProvider) هنا لأن ذلك كان يُعيد
    // بناء القائمة الكاملة كل X ثانية أثناء التشغيل ويُفقد موضع التمرير.
  }

  Future<String> _resolveUri(LessonModel lesson) async {
    final local = await DatabaseHelper.instance.getDownloadPath(lesson.id);
    if (local != null && local.isNotEmpty) return local;
    return lesson.fileUrl;
  }

  Future<void> play(LessonModel lesson, {Duration? startPosition}) async {
    try {
      state = state.copyWith(
        currentLesson: lesson,
        status: PlayerStatus.loading,
        errorMessage: null,
      );

      final saved = await DatabaseHelper.instance.getProgress(lesson.id);
      final start = startPosition ??
          (saved != null
              ? Duration(seconds: saved.position)
              : Duration.zero);

      final uri = await _resolveUri(lesson);
      await _handler.setLessonSource(
        lesson: lesson,
        uri: uri,
        startPosition: start,
      );
      await _handler.play();

      state = state.copyWith(
        status: PlayerStatus.playing,
        duration: Duration(seconds: lesson.duration),
        position: start,
        speed: _handler.player.speed,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'تعذّر تشغيل الدرس: $e',
      );
    }
  }

  Future<void> pause() async {
    await _handler.pause();
    await _saveCurrentProgress();
    state = state.copyWith(status: PlayerStatus.paused);
  }

  Future<void> resume() async {
    await _handler.play();
    state = state.copyWith(status: PlayerStatus.playing);
  }

  Future<void> seek(Duration position) async {
    await _handler.seek(position);
    state = state.copyWith(position: position);
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> skipForward30() => _handler.skipForward30();

  Future<void> skipBackward30() => _handler.skipBackward30();

  Future<void> playNext() async {
    final current = state.currentLesson;
    if (current == null) return;
    final lessons = await ArchiveService.instance.loadLessons();
    final index = lessons.indexWhere((l) => l.id == current.id);
    if (index >= 0 && index < lessons.length - 1) {
      await play(lessons[index + 1]);
    }
  }

  Future<void> playPrevious() async {
    final current = state.currentLesson;
    if (current == null) return;
    final lessons = await ArchiveService.instance.loadLessons();
    final index = lessons.indexWhere((l) => l.id == current.id);
    if (index > 0) {
      await play(lessons[index - 1]);
    }
  }

  Future<void> togglePlayPause() async {
    if (state.status == PlayerStatus.playing) {
      await pause();
    } else if (state.status == PlayerStatus.paused) {
      await resume();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playbackSub?.cancel();
    _saveTimer?.cancel();
    _saveCurrentProgress();
    super.dispose();
  }
}
