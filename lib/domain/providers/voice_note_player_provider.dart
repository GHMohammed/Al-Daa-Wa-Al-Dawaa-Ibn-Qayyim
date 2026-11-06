import 'dart:async';

import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class VoicePlayback {
  const VoicePlayback({
    this.path,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// الملاحظة الصوتية المحمّلة حالياً (null إذا لا شيء)
  final String? path;
  final bool playing;
  final Duration position;
  final Duration duration;

  bool isActive(String p) => path == p;
}

/// مشغّل مستقل للملاحظات الصوتية — منفصل عن مشغّل الدروس وخدمة الخلفية
final voiceNotePlayerProvider =
    StateNotifierProvider<VoiceNotePlayer, VoicePlayback>(
  (ref) => VoiceNotePlayer(ref),
);

class VoiceNotePlayer extends StateNotifier<VoicePlayback> {
  VoiceNotePlayer(this._ref) : super(const VoicePlayback()) {
    _subs = [
      _player.positionStream.listen((p) {
        if (state.path != null) state = _copy(position: p);
      }),
      _player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          _player.pause();
          _player.seek(Duration.zero);
          state = _copy(playing: false, position: Duration.zero);
        } else if (state.path != null) {
          state = _copy(playing: s.playing);
        }
      }),
    ];
  }

  final Ref _ref;
  final _player = AudioPlayer();
  late final List<StreamSubscription<Object?>> _subs;

  VoicePlayback _copy(
          {bool? playing, Duration? position, Duration? duration}) =>
      VoicePlayback(
        path: state.path,
        playing: playing ?? state.playing,
        position: position ?? state.position,
        duration: duration ?? state.duration,
      );

  /// تشغيل/إيقاف ملاحظة — يوقف الدرس مؤقتاً حتى لا يتداخل الصوتان
  Future<void> toggle(String path) async {
    if (state.isActive(path)) {
      if (state.playing) {
        await _player.pause();
      } else {
        await _pauseLesson();
        await _player.play();
      }
      return;
    }
    await _pauseLesson();
    final duration = await _player.setFilePath(path);
    state = VoicePlayback(
      path: path,
      playing: true,
      duration: duration ?? Duration.zero,
    );
    await _player.play();
  }

  /// يوقف التشغيل ويفرّغ المشغّل (قبل حذف الملف مثلاً)
  Future<void> stop() async {
    await _player.stop();
    state = const VoicePlayback();
  }

  Future<void> _pauseLesson() async {
    final lesson = _ref.read(playerProvider);
    if (lesson.status == PlayerStatus.playing) {
      await _ref.read(playerProvider.notifier).pause();
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
