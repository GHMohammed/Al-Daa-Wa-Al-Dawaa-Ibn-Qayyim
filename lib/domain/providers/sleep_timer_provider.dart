import 'dart:async';

import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// مؤقت النوم: إما مدة محددة (بالوقت الفعلي) أو حتى نهاية الدرس الحالي
class SleepTimer {
  const SleepTimer.duration(Duration this.remaining) : endOfLesson = false;
  const SleepTimer.endOfLesson()
      : remaining = null,
        endOfLesson = true;

  final Duration? remaining;
  final bool endOfLesson;
}

/// null = لا مؤقت
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimer?>(
  SleepTimerNotifier.new,
);

class SleepTimerNotifier extends StateNotifier<SleepTimer?> {
  SleepTimerNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _ticker;
  DateTime? _endsAt;

  /// آخر ثوانٍ يُخفَض فيها الصوت تدريجياً بدل التوقف المفاجئ
  static const _fade = Duration(seconds: 10);

  void start(Duration duration) {
    _reset();
    _endsAt = DateTime.now().add(duration);
    state = SleepTimer.duration(duration);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void startEndOfLesson() {
    _reset();
    state = const SleepTimer.endOfLesson();
  }

  void cancel() {
    _reset();
    state = null;
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    final player = _ref.read(playerProvider.notifier);
    if (left <= Duration.zero) {
      // نوقف أولاً ثم نعيد الصوت، حتى لا يعلو لحظةً قبل التوقف
      _ticker?.cancel();
      player.pause().whenComplete(cancel);
      return;
    }
    if (left < _fade) {
      player.setVolume(left.inMilliseconds / _fade.inMilliseconds);
    }
    state = SleepTimer.duration(left);
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    _ref.read(playerProvider.notifier).setVolume(1);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
