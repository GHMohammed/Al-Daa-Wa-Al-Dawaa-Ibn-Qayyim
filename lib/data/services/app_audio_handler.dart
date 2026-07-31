import 'dart:async';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// معالج الصوت للتشغيل في الخلفية مع just_audio
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler() {
    _playbackEventSub = _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
    _positionSub = _player.positionStream.listen((_) {
      playbackState.add(_transformEvent(_player.playbackEvent));
    });
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<Duration>? _positionSub;
  LessonModel? _currentLesson;

  LessonModel? get currentLesson => _currentLesson;
  AudioPlayer get player => _player;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.rewind,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    );
  }

  Future<void> setLessonSource({
    required LessonModel lesson,
    required String uri,
    Duration? startPosition,
  }) async {
    _currentLesson = lesson;
    mediaItem.add(
      MediaItem(
        id: lesson.id.toString(),
        title: lesson.title,
        artist: AppConstants.sheikhName,
        duration: Duration(seconds: lesson.duration),
        artUri: Uri.parse('asset:///${AppConstants.coverImagePath}'),
      ),
    );

    final source = uri.startsWith('http')
        ? AudioSource.uri(Uri.parse(uri))
        : AudioSource.file(uri);

    await _player.setAudioSource(
      source,
      initialPosition: startPosition ?? Duration.zero,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> skipForward30() async {
    final target = _player.position + const Duration(seconds: 30);
    final max = _player.duration ?? Duration.zero;
    await seek(target > max ? max : target);
  }

  Future<void> skipBackward30() async {
    final target = _player.position - const Duration(seconds: 30);
    await seek(target.isNegative ? Duration.zero : target);
  }

  Future<void> stopPlayer() async {
    await _player.stop();
    _currentLesson = null;
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> dispose() async {
    await _playbackEventSub?.cancel();
    await _positionSub?.cancel();
    await _player.dispose();
  }
}
