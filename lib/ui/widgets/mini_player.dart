import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// مشغّل مصغّر عائم فوق شريط التنقل
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);

    if (!player.hasActiveLesson) return const SizedBox.shrink();

    final lesson = player.currentLesson!;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final playing = player.status == PlayerStatus.playing;
    final fraction = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Material(
        color: colors.header,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/player/${lesson.id}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.xxs,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.gold, width: 1.2),
                      ),
                      child: Text(
                        '${lesson.id}',
                        style: text.labelMedium?.copyWith(
                          color: colors.gold,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium
                                ?.copyWith(color: colors.onHeader),
                          ),
                          Text(
                            AppConstants.formatDuration(player.position),
                            style: text.labelSmall
                                ?.copyWith(color: colors.onHeaderMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colors.onHeader,
                        size: 30,
                      ),
                      tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل',
                      onPressed: () =>
                          ref.read(playerProvider.notifier).togglePlayPause(),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: fraction,
                minHeight: 2,
                color: colors.gold,
                backgroundColor: colors.onHeaderTrack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
