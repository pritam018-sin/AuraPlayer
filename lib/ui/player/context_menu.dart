import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../modals/media_info_modal.dart';
import '../modals/video_adjustments_modal.dart';
import 'audio_sub_sheet.dart';

class VideoContextMenu {
  static void show(
    BuildContext context,
    Offset position,
    AuraPlayerWrapper playerWrapper,
    WidgetRef ref,
  ) {
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final isPlaying = playerWrapper.player.state.playing;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: AppTheme.surface.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          height: 34,
          onTap: () => playerWrapper.playOrPause(),
          child: Row(
            children: [
              Icon(isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 16, color: AppTheme.accent),
              const SizedBox(width: 10),
              Text(isPlaying ? 'Pause' : 'Play', style: AppTheme.bodySmall),
              const Spacer(),
              Text('Space', style: AppTheme.caption),
            ],
          ),
        ),
        PopupMenuItem(
          height: 34,
          onTap: () => ref.read(playlistProvider.notifier).stopAndClose(),
          child: Row(
            children: [
              const Icon(CupertinoIcons.stop_fill, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Stop & Return to Library', style: AppTheme.bodySmall),
              const Spacer(),
              Text('S', style: AppTheme.caption),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),

        PopupMenuItem(
          height: 34,
          onTap: () => AudioSubtitleSheet.show(context, playerWrapper),
          child: Row(
            children: [
              const Icon(CupertinoIcons.captions_bubble_fill, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Audio & Subtitle Tracks...', style: AppTheme.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          height: 34,
          onTap: () => VideoAdjustmentsModal.show(context, playerWrapper),
          child: Row(
            children: [
              const Icon(CupertinoIcons.dial_fill, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Video Adjustments & Filters...', style: AppTheme.bodySmall),
            ],
          ),
        ),
        PopupMenuItem(
          height: 34,
          onTap: () => MediaInfoModal.show(context, playerWrapper),
          child: Row(
            children: [
              const Icon(CupertinoIcons.info_circle, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Media Information & Codecs', style: AppTheme.bodySmall),
              const Spacer(),
              Text('Ctrl+I', style: AppTheme.caption),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),

        PopupMenuItem(
          height: 34,
          onTap: () async {
            final path = await playerWrapper.takeSnapshot();
            if (context.mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Snapshot saved: ${path.split(RegExp(r'[/\\]')).last}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.surfaceSecondary,
                ),
              );
            }
          },
          child: Row(
            children: [
              const Icon(CupertinoIcons.camera_fill, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Take Snapshot', style: AppTheme.bodySmall),
              const Spacer(),
              Text('Shift+S', style: AppTheme.caption),
            ],
          ),
        ),
        PopupMenuItem(
          height: 34,
          onTap: () => windowNotifier.toggleFullscreen(),
          child: Row(
            children: [
              const Icon(CupertinoIcons.fullscreen, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text('Toggle Fullscreen', style: AppTheme.bodySmall),
              const Spacer(),
              Text('F', style: AppTheme.caption),
            ],
          ),
        ),
      ],
    );
  }
}
