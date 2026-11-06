import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// مشغّل مصغّر في أسفل الشاشة الرئيسية
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);

    if (!player.hasActiveLesson) return const SizedBox.shrink();

    final lesson = player.currentLesson!;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.header,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          onTap: () => context.push('/player/${lesson.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // أيقونة الموسيقى داخل Container دائري
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.onHeaderTrack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: colors.onHeader,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // عنوان الدرس + الوقت الحالي
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          color: colors.onHeader,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.formatDuration(player.position),
                        style: TextStyle(
                          color: colors.onHeaderMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // زر تشغيل / إيقاف
                IconButton(
                  icon: Icon(
                    player.status == PlayerStatus.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: colors.onHeader,
                    size: 28,
                  ),
                  onPressed: () =>
                      ref.read(playerProvider.notifier).togglePlayPause(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
