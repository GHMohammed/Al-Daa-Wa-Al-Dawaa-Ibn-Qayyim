import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// شاشة المشغّل الكامل
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePlaying());
  }

  Future<void> _ensurePlaying() async {
    final item = ref.read(lessonByIdProvider(widget.lessonId));
    if (item == null) return;
    final player = ref.read(playerProvider);
    if (player.currentLesson?.id != widget.lessonId) {
      await ref.read(playerProvider.notifier).play(item.lesson);
    }
  }

  /// يُعيد ترتيب الدرس بالعربي الكامل حتى 83
  /// مثال: 1→الأول، 21→الحادي والعشرون، 83→الثالث والثمانون
  String _lessonNumber(int id) {
    // الآحاد المنفردة (1–9)
    const ones = [
      '', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع',
    ];
    // الآحاد مع العقود (21، 31...): رقم 1 يصبح "الحادي"
    const compoundOnes = [
      '', 'الحادي', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع',
    ];
    const teens = [
      'العاشر', 'الحادي عشر', 'الثاني عشر', 'الثالث عشر',
      'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر',
      'الثامن عشر', 'التاسع عشر',
    ];
    const tens = [
      '', '', 'العشرون', 'الثلاثون', 'الأربعون', 'الخمسون',
      'الستون', 'السبعون', 'الثمانون', 'التسعون',
    ];

    if (id <= 9) return 'الدرس ${ones[id]}';
    if (id <= 19) return 'الدرس ${teens[id - 10]}';

    final ten = id ~/ 10;
    final one = id % 10;
    if (one == 0) return 'الدرس ${tens[ten]}';
    return 'الدرس ${compoundOnes[one]} و${tens[ten]}';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final item = ref.watch(lessonByIdProvider(widget.lessonId));
    final lesson = item?.lesson ?? player.currentLesson;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المشغّل')),
        body: const Center(child: Text('الدرس غير موجود')),
      );
    }

    final duration = player.duration.inSeconds > 0
        ? player.duration
        : Duration(seconds: lesson.duration);
    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : lesson.duration.toDouble();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.pop(),
        ),
        title: Text(_lessonNumber(lesson.id)),
      ),
      // SingleChildScrollView في الخارج يضمن إمكانية السكرول دائماً
      // ConstrainedBox(minHeight) يحافظ على تمركز المحتوى عمودياً
      // حين يكون أصغر من الشاشة، وييسّر السكرول على الشاشات الصغيرة
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // غلاف الكتاب
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1D9E75).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 72,
                      color: Color(0xFF1D9E75),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'الداء والدواء',
                      style: TextStyle(
                        color: Color(0xFF0F6E56),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // عنوان الدرس
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.sheikhName,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              // شريط التقديم
              Slider(
                value: player.position.inMilliseconds
                    .toDouble()
                    .clamp(0.0, maxMs),
                max: maxMs,
                onChanged: (v) {
                  ref
                      .read(playerProvider.notifier)
                      .seek(Duration(milliseconds: v.toInt()));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppConstants.formatDuration(player.position)),
                    Text(AppConstants.formatDuration(duration)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // أزرار التحكم
              // FittedBox يُقلّص الصف كاملاً على الشاشات الضيقة
              // دون المساس بالمسافات بين الأزرار أو أحجامها
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).skipBackward30(),
                      icon: const Icon(Icons.replay_30),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).playPrevious(),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    const SizedBox(width: 24),
                    // GestureDetector بدل IconButton داخل CircleAvatar
                    // لتجنب تعارض hit areas بين الأيقونة والدائرة
                    GestureDetector(
                      onTap: () =>
                          ref.read(playerProvider.notifier).togglePlayPause(),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          player.status == PlayerStatus.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).playNext(),
                      icon: const Icon(Icons.skip_next),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ref.read(playerProvider.notifier).skipForward30(),
                      icon: const Icon(Icons.forward_30),
                    ),
                  ],
                ),
              ),
              // رسالة الخطأ إن وُجدت
              if (player.status == PlayerStatus.error &&
                  player.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    player.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
