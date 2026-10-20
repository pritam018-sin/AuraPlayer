import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';
import 'audio_sub_sheet.dart';
import 'seek_bar.dart';

class FloatingControls extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;
  final bool isVisible;

  const FloatingControls({
    super.key,
    required this.playerWrapper,
    required this.isVisible,
  });

  @override
  ConsumerState<FloatingControls> createState() => _FloatingControlsState();
}

class _FloatingControlsState extends ConsumerState<FloatingControls> {
  bool _isHoveringVolume = false;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.playerWrapper.player;
    final playlist = ref.watch(playlistProvider);
    final playlistNotifier = ref.read(playlistProvider.notifier);
    final windowState = ref.watch(windowControlsProvider);
    final windowNotifier = ref.read(windowControlsProvider.notifier);

    return StreamBuilder<bool>(
      stream: player.stream.playing,
      initialData: player.state.playing,
      builder: (context, playingSnap) {
        final isPlaying = playingSnap.data ?? false;

        return StreamBuilder<Duration>(
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: player.stream.duration,
              initialData: player.state.duration,
              builder: (context, durSnap) {
                final duration = durSnap.data ?? Duration.zero;

                return StreamBuilder<Duration>(
                  stream: player.stream.buffer,
                  initialData: player.state.buffer,
                  builder: (context, bufSnap) {
                    final buffer = bufSnap.data ?? Duration.zero;

                    return StreamBuilder<double>(
                      stream: player.stream.volume,
                      initialData: player.state.volume,
                      builder: (context, volSnap) {
                        final volume = volSnap.data ?? 100.0;

                        return StreamBuilder<double>(
                          stream: player.stream.rate,
                          initialData: player.state.rate,
                          builder: (context, rateSnap) {
                            final rate = rateSnap.data ?? 1.0;

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              opacity: widget.isVisible ? 1.0 : 0.0,
                              child: IgnorePointer(
                                ignoring: !widget.isVisible,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: FrostedGlass(
                                    borderRadius: 20,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    fillColor: AppTheme.controlPillFill,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Seek Bar with hover timestamp
                                        CustomSeekBar(
                                          position: position,
                                          duration: duration,
                                          buffer: buffer,
                                          onSeek: (pos) => widget.playerWrapper.seek(pos),
                                        ),

                                        const SizedBox(height: 6),

                                        // Controls Row
                                        Row(
                                          children: [
                                            // Previous Track
                                            _iconButton(
                                              tooltip: 'Previous',
                                              icon: CupertinoIcons.backward_fill,
                                              size: 16,
                                              enabled: playlist.hasPrev,
                                              onTap: () => playlistNotifier.prev(),
                                            ),
                                            const SizedBox(width: 4),

                                            // Replay 5s
                                            _iconButton(
                                              tooltip: 'Rewind 5s (Left)',
                                              icon: CupertinoIcons.gobackward,
                                              size: 18,
                                              onTap: () => widget.playerWrapper
                                                  .seekRelative(const Duration(seconds: -5)),
                                            ),
                                            const SizedBox(width: 6),

                                            // Play / Pause Prominent Button
                                            GestureDetector(
                                              onTap: () => widget.playerWrapper.playOrPause(),
                                              child: Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accent,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppTheme.accent.withValues(alpha: 0.35),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    isPlaying
                                                        ? CupertinoIcons.pause_fill
                                                        : CupertinoIcons.play_fill,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            // Forward 5s
                                            _iconButton(
                                              tooltip: 'Forward 5s (Right)',
                                              icon: CupertinoIcons.goforward,
                                              size: 18,
                                              onTap: () => widget.playerWrapper
                                                  .seekRelative(const Duration(seconds: 5)),
                                            ),
                                            const SizedBox(width: 4),

                                            // Next Track
                                            _iconButton(
                                              tooltip: 'Next',
                                              icon: CupertinoIcons.forward_fill,
                                              size: 16,
                                              enabled: playlist.hasNext,
                                              onTap: () => playlistNotifier.next(),
                                            ),

                                            const SizedBox(width: 14),

                                            // Timestamps: 00:00 / 00:00
                                            Text(
                                              '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                              style: AppTheme.caption.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),

                                            const Spacer(),

                                            // Volume Slider & Mute
                                            MouseRegion(
                                              onEnter: (_) =>
                                                  setState(() => _isHoveringVolume = true),
                                              onExit: (_) =>
                                                  setState(() => _isHoveringVolume = false),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _iconButton(
                                                    tooltip: volume == 0 ? 'Unmute (M)' : 'Mute (M)',
                                                    icon: volume == 0
                                                        ? CupertinoIcons.volume_off
                                                        : (volume < 50
                                                            ? CupertinoIcons.volume_down
                                                            : CupertinoIcons.volume_up),
                                                    size: 18,
                                                    onTap: () => widget.playerWrapper.toggleMute(),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    curve: Curves.easeOutCubic,
                                                    width: _isHoveringVolume ? 90 : 0,
                                                    child: _isHoveringVolume
                                                        ? SliderTheme(
                                                            data: SliderThemeData(
                                                              trackHeight: 3.5,
                                                              thumbShape:
                                                                  const RoundSliderThumbShape(
                                                                enabledThumbRadius: 6,
                                                              ),
                                                              overlayShape:
                                                                  const RoundSliderOverlayShape(
                                                                overlayRadius: 10,
                                                              ),
                                                              activeTrackColor: AppTheme.accent,
                                                              inactiveTrackColor: Colors.white24,
                                                              thumbColor: Colors.white,
                                                            ),
                                                            child: Slider(
                                                              value: volume.clamp(0.0, 100.0),
                                                              min: 0.0,
                                                              max: 100.0,
                                                              onChanged: (v) =>
                                                                  widget.playerWrapper.setVolume(v),
                                                            ),
                                                          )
                                                        : const SizedBox.shrink(),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Playback Speed Pill
                                            Tooltip(
                                              message: 'Speed ([ ])',
                                              child: InkWell(
                                                onTap: () => widget.playerWrapper.cycleSpeed(),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.surfaceSecondary,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppTheme.glassBorder),
                                                  ),
                                                  child: Text(
                                                    '${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 2)}x',
                                                    style: AppTheme.caption.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: rate != 1.0
                                                          ? AppTheme.accent
                                                          : AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Audio & Subtitles Menu
                                            _iconButton(
                                              tooltip: 'Audio & Subtitles',
                                              icon: CupertinoIcons.captions_bubble,
                                              size: 18,
                                              onTap: () => AudioSubtitleSheet.show(
                                                  context, widget.playerWrapper),
                                            ),

                                            const SizedBox(width: 6),

                                            // Fullscreen Toggle
                                            _iconButton(
                                              tooltip: windowState.isFullscreen
                                                  ? 'Exit Fullscreen (Esc)'
                                                  : 'Fullscreen (F)',
                                              icon: windowState.isFullscreen
                                                  ? CupertinoIcons.fullscreen_exit
                                                  : CupertinoIcons.fullscreen,
                                              size: 18,
                                              onTap: () => windowNotifier.toggleFullscreen(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    double size = 18,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: size,
            color: enabled ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }
}
