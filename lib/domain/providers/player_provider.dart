import 'dart:async';
import 'dart:io';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/local/download_manager.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/data/remote/archive_service.dart';
import 'package:al_daa_wal_dawaa/data/services/app_audio_handler.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/listening_stats.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _handler
      ..onSkipToNext = playNext
      ..onSkipToPrevious = playPrevious;
    _initListeners();
    _restoreSpeed();
    _listenTicker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const _speedKey = 'playback_speed';

  /// السرعة المختارة سابقاً تُطبّق على كل الدروس حتى يغيّرها المستخدم
  Future<void> _restoreSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_speedKey);
    if (saved == null || !mounted) return;
    await _handler.setSpeed(saved);
    state = state.copyWith(speed: saved);
  }

  final Ref _ref;
  late final AppAudioHandler _handler;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _playbackSub;

  /// ثوانٍ استُمع إليها فعلاً (وقت حقيقي) ولم تُحفظ في السجل اليومي بعد
  Timer? _listenTicker;
  int _pendingListen = 0;

  void _tick() {
    // توقف من أي مكان (الإشعار، نهاية الدرس…): نحفظ ما تجمّع
    if (!_handler.player.playing) return _flushListening();
    if (++_pendingListen >= 30) _flushListening();
  }

  void _flushListening() {
    if (_pendingListen == 0) return;
    final seconds = _pendingListen;
    _pendingListen = 0;
    _ref.read(listeningLogProvider.notifier).add(seconds);
  }

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

    final progress = ProgressModel(
      lessonId: lesson.id,
      position: position,
      totalDuration: total,
      completed: completed,
      lastPlayed: DateTime.now(),
    );
    await DatabaseHelper.instance.saveProgress(progress);
    // نحدّث progressMapProvider فقط — invalidate(lessonsProvider) كان يُعيد
    // بناء القائمة الكاملة ويُفقد موضع التمرير
    if (mounted) _ref.read(progressMapProvider.notifier).update(progress);
  }

  Future<String> _resolveUri(LessonModel lesson) async {
    final local = await DatabaseHelper.instance.getDownloadPath(lesson.id);
    if (local != null && local.isNotEmpty) {
      if (await File(local).exists()) return local;
      // الملف حُذف من الجهاز — ننظّف السجل ونرجع للبث
      await DatabaseHelper.instance.deleteDownload(lesson.id);
      _ref
          .read(downloadStatusProvider.notifier)
          .setStatus(lesson.id, DownloadStatus.notDownloaded);
    }
    // نفس صيغة التحميل حتى لا تعترض صفحة تأكيد Google Drive البث
    return DownloadManager.normalizeDownloadUrl(lesson.fileUrl);
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
          (saved != null ? Duration(seconds: saved.position) : Duration.zero);

      final uri = await _resolveUri(lesson);
      await _handler.setLessonSource(
        lesson: lesson,
        uri: uri,
        startPosition: start,
      );
      await _handler.play();

      state = state.copyWith(
        status: PlayerStatus.playing,
        // المدة الحقيقية من الملف؛ مدة JSON تقديرية فقط
        duration:
            _handler.player.duration ?? Duration(seconds: lesson.duration),
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
    _flushListening();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speedKey, speed);
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
    _handler
      ..onSkipToNext = null
      ..onSkipToPrevious = null;
    _positionSub?.cancel();
    _playbackSub?.cancel();
    _listenTicker?.cancel();
    _flushListening();
    _saveCurrentProgress();
    super.dispose();
  }
}
