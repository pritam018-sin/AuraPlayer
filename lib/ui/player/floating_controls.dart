import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import 'audio_sub_sheet.dart';
import 'seek_bar.dart';
import 'video_glassy_menu.dart';

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
  bool _showRemainingTime = false;
  Duration? _draggedSeekPosition;

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
                            final isLive = widget.playerWrapper.isLiveStream;

                            // Instantaneous sync during scrubbing
                            final effectivePos = _draggedSeekPosition ?? position;

                            final timeDisplay = isLive
                                ? '● LIVE'
                                : (_showRemainingTime
                                    ? '-${_formatDuration(duration - effectivePos)} / ${_formatDuration(duration)}'
                                    : '${_formatDuration(effectivePos)} / ${_formatDuration(duration)}');

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              opacity: widget.isVisible ? 1.0 : 0.0,
                              child: IgnorePointer(
                                ignoring: !widget.isVisible,
                                child: Container(
                                  // Clean, non-blurry translucent gradient scrim (no blur/frosted glass over video)
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.75),
                                        Colors.black.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                                  child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 1. Edge-to-Edge Progress Seek Bar with Draggable Radio Button
                                          CustomSeekBar(
                                            position: position,
                                            duration: duration,
                                            buffer: buffer,
                                            isLive: isLive,
                                            onDragChanged: (d) {
                                              setState(() => _draggedSeekPosition = d);
                                            },
                                            onSeek: (pos) => widget.playerWrapper.seek(pos),
                                          ),

                                          const SizedBox(height: 10),

                                          // 2. Playback Control Strip
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Left Group: Back Button + Timestamps & Track Navigation
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [

                                                  _iconButton(
                                                    tooltip: 'Previous Video (P)',
                                                    icon: Icons.skip_previous_rounded,
                                                    size: 18,
                                                    enabled: playlist.hasPrev,
                                                    onTap: () => playlistNotifier.prev(),
                                                  ),
                                                  const SizedBox(width: 4),

                                                  _iconButton(
                                                    tooltip: 'Rewind 10s (Left)',
                                                    icon: Icons.replay_10_rounded,
                                                    size: 20,
                                                    onTap: () => widget.playerWrapper
                                                        .seekRelative(const Duration(seconds: -10)),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // Primary Play / Pause Hero Button
                                                  GestureDetector(
                                                    onTap: () => widget.playerWrapper.playOrPause(),
                                                    child: Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        gradient: AppTheme.auraGradient,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppTheme.accent.withValues(alpha: 0.5),
                                                            blurRadius: 14,
                                                            spreadRadius: 1,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          isPlaying
                                                              ? Icons.pause_rounded
                                                              : Icons.play_arrow_rounded,
                                                          size: 24,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  _iconButton(
                                                    tooltip: 'Forward 10s (Right)',
                                                    icon: Icons.forward_10_rounded,
                                                    size: 20,
                                                    onTap: () => widget.playerWrapper
                                                        .seekRelative(const Duration(seconds: 10)),
                                                  ),
                                                  const SizedBox(width: 4),

                                                  _iconButton(
                                                    tooltip: 'Next Video (N)',
                                                    icon: Icons.skip_next_rounded,
                                                    size: 18,
                                                    enabled: playlist.hasNext,
                                                    onTap: () => playlistNotifier.next(),
                                                  ),

                                                  const SizedBox(width: 14),

                                                  // Time Indicator
                                                  InkWell(
                                                    onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: AppTheme.glassBorder),
                                                      ),
                                                      child: Text(
                                                        timeDisplay,
                                                        style: AppTheme.caption.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const Spacer(),

                                              // Right Group: Streamlined Core Controls
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // 1. Volume Control Slider (Boost up to 150%)
                                                  MouseRegion(
                                                    onEnter: (_) => setState(() => _isHoveringVolume = true),
                                                    onExit: (_) => setState(() => _isHoveringVolume = false),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        _iconButton(
                                                          tooltip: volume == 0 ? 'Unmute (M)' : 'Mute (M)',
                                                          icon: volume == 0
                                                              ? Icons.volume_off_rounded
                                                              : (volume < 50
                                                                  ? Icons.volume_down_rounded
                                                                  : Icons.volume_up_rounded),
                                                          size: 19,
                                                          onTap: () => widget.playerWrapper.toggleMute(),
                                                        ),
                                                        AnimatedContainer(
                                                          duration: const Duration(milliseconds: 180),
                                                          curve: Curves.easeOutCubic,
                                                          width: _isHoveringVolume ? 130 : 0,
                                                          child: _isHoveringVolume
                                                              ? Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: SliderTheme(
                                                                        data: SliderThemeData(
                                                                          trackHeight: 3.5,
                                                                          thumbShape: const RoundSliderThumbShape(
                                                                            enabledThumbRadius: 6,
                                                                          ),
                                                                          overlayShape: const RoundSliderOverlayShape(
                                                                            overlayRadius: 10,
                                                                          ),
                                                                          activeTrackColor: volume > 100
                                                                              ? Colors.orangeAccent
                                                                              : AppTheme.accent,
                                                                          inactiveTrackColor: Colors.white24,
                                                                          thumbColor: Colors.white,
                                                                        ),
                                                                        child: Slider(
                                                                          value: volume.clamp(0.0, 150.0),
                                                                          min: 0.0,
                                                                          max: 150.0,
                                                                          onChanged: (v) => widget.playerWrapper.setVolume(v),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '${volume.toInt()}%',
                                                                      style: AppTheme.caption.copyWith(
                                                                        fontSize: 10.5,
                                                                        fontWeight: FontWeight.w600,
                                                                        color: volume > 100 ? Colors.orangeAccent : Colors.white70,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              : const SizedBox.shrink(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 2. Audio & Subtitles Quick Switcher
                                                  _iconButton(
                                                    tooltip: 'Audio Tracks & Subtitles',
                                                    icon: Icons.closed_caption_rounded,
                                                    size: 19,
                                                    onTap: () => AudioSubtitleSheet.show(context, widget.playerWrapper),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 3. Playlist / Queue Drawer Toggle
                                                  _iconButton(
                                                    tooltip: 'Playlist / Queue (Ctrl+L)',
                                                    icon: Icons.queue_music_rounded,
                                                    size: 19,
                                                    isActive: windowState.isPlaylistOpen,
                                                    onTap: () => windowNotifier.togglePlaylist(),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 4. Studio Pro Inspector Drawer Toggle
                                                  _iconButton(
                                                    tooltip: 'Studio Inspector (I)',
                                                    icon: Icons.tune_rounded,
                                                    size: 19,
                                                    isActive: windowState.isInspectorOpen,
                                                    onTap: () => windowNotifier.toggleInspector(),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 5. Fullscreen Toggle
                                                  _iconButton(
                                                    tooltip: windowState.isFullscreen ? 'Exit Fullscreen (Esc)' : 'Fullscreen (F)',
                                                    icon: windowState.isFullscreen
                                                        ? Icons.fullscreen_exit_rounded
                                                        : Icons.fullscreen_rounded,
                                                    size: 21,
                                                    onTap: () => windowNotifier.toggleFullscreen(),
                                                  ),

                                                  const SizedBox(width: 4),

                                                  // 7. More Options Glassy Menu (3-dots)
                                                  Builder(
                                                    builder: (btnCtx) => _iconButton(
                                                      tooltip: 'More Options (Glassy Menu)',
                                                      icon: Icons.more_vert_rounded,
                                                      size: 19,
                                                      onTap: () {
                                                        final box = btnCtx.findRenderObject() as RenderBox?;
                                                        final pos = box != null
                                                            ? box.localToGlobal(Offset.zero)
                                                            : const Offset(100, 100);
                                                        VideoGlassyMenu.show(
                                                          context: context,
                                                          position: Offset(pos.dx - 280, pos.dy - 460),
                                                          playerWrapper: widget.playerWrapper,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
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
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? Border.all(color: AppTheme.accent.withValues(alpha: 0.6)) : null,
          ),
          child: Icon(
            icon,
            size: size,
            color: isActive ? AppTheme.accent : (enabled ? Colors.white : Colors.white30),
          ),
        ),
      ),
    );
  }
}
