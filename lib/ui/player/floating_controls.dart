import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import 'audio_sub_sheet.dart';
import 'seek_bar.dart';
import '../modals/cinema_studio_modal.dart';

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

  void _cycleAspectRatio() {
    final current = widget.playerWrapper.currentAspectRatio;
    const ratios = [null, '16:9', '4:3', '21:9'];
    final idx = ratios.indexOf(current);
    final next = ratios[(idx + 1) % ratios.length];
    widget.playerWrapper.setAspectRatio(next);
    setState(() {});
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
                                  // Cinematic edge-to-edge gradient scrim (NO BOX/PILL BACKGROUND)
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.94),
                                        Colors.black.withValues(alpha: 0.65),
                                        Colors.black.withValues(alpha: 0.20),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.45, 0.80, 1.0],
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
                                          // Left Group: Timestamps & Track Navigation
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _iconButton(
                                                tooltip: 'Previous Video (P)',
                                                icon: CupertinoIcons.backward_fill,
                                                size: 15,
                                                enabled: playlist.hasPrev,
                                                onTap: () => playlistNotifier.prev(),
                                              ),
                                              const SizedBox(width: 4),

                                              _iconButton(
                                                tooltip: 'Rewind 10s (Left)',
                                                icon: CupertinoIcons.gobackward_10,
                                                size: 18,
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
                                                          ? CupertinoIcons.pause_fill
                                                          : CupertinoIcons.play_fill,
                                                      size: 20,
                                                      color: const Color(0xFF04131F),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              _iconButton(
                                                tooltip: 'Forward 10s (Right)',
                                                icon: CupertinoIcons.goforward_10,
                                                size: 18,
                                                onTap: () => widget.playerWrapper
                                                    .seekRelative(const Duration(seconds: 10)),
                                              ),
                                              const SizedBox(width: 4),

                                              _iconButton(
                                                tooltip: 'Next Video (N)',
                                                icon: CupertinoIcons.forward_fill,
                                                size: 15,
                                                enabled: playlist.hasNext,
                                                onTap: () => playlistNotifier.next(),
                                              ),
                                              const SizedBox(width: 4),

                                              _iconButton(
                                                tooltip: 'Stop & Return to Library (S)',
                                                icon: CupertinoIcons.stop_fill,
                                                size: 15,
                                                onTap: () => playlistNotifier.stopAndClose(),
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

                                          // Right Group: Volume + Power VLC Tools
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Volume Control Slider (Boost up to 150%)
                                              MouseRegion(
                                                onEnter: (_) => setState(() => _isHoveringVolume = true),
                                                onExit: (_) => setState(() => _isHoveringVolume = false),
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

                                              const SizedBox(width: 8),

                                              // Aspect Ratio Quick Switcher
                                              Tooltip(
                                                message: 'Aspect Ratio: ${widget.playerWrapper.currentAspectRatio ?? 'Default'}',
                                                child: InkWell(
                                                  onTap: _cycleAspectRatio,
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: AppTheme.glassBorder),
                                                    ),
                                                    child: Text(
                                                      widget.playerWrapper.currentAspectRatio ?? 'Ratio',
                                                      style: AppTheme.caption.copyWith(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Playback Speed Pill
                                              Tooltip(
                                                message: 'Speed ([ ])',
                                                child: InkWell(
                                                  onTap: () => widget.playerWrapper.cycleSpeed(),
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: AppTheme.glassBorder),
                                                    ),
                                                    child: Text(
                                                      '${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 2)}x',
                                                      style: AppTheme.caption.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 11,
                                                        color: rate != 1.0 ? AppTheme.accent : Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Audio & Subtitles
                                              _iconButton(
                                                tooltip: 'Audio Tracks & Subtitles',
                                                icon: CupertinoIcons.captions_bubble,
                                                size: 18,
                                                onTap: () => AudioSubtitleSheet.show(context, widget.playerWrapper),
                                              ),

                                              const SizedBox(width: 4),

                                              // Cinema Studio Pro Inspector HUD
                                              _iconButton(
                                                tooltip: 'Cinema Studio Pro Inspector (I)',
                                                icon: CupertinoIcons.slider_horizontal_3,
                                                size: 18,
                                                onTap: () => CinemaStudioModal.show(context, widget.playerWrapper),
                                              ),

                                              const SizedBox(width: 4),

                                              // Snapshot High-Res Capture
                                              _iconButton(
                                                tooltip: 'Take Snapshot (Shift+S)',
                                                icon: CupertinoIcons.camera_fill,
                                                size: 17,
                                                onTap: () async {
                                                  final path = await widget.playerWrapper.takeSnapshot();
                                                  if (context.mounted && path != null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Snapshot saved: ${path.split(RegExp(r'[/\\]')).last}'),
                                                        behavior: SnackBarBehavior.floating,
                                                        backgroundColor: const Color(0xFF1E1E28),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),

                                              const SizedBox(width: 4),

                                              // Playlist Drawer Toggle
                                              _iconButton(
                                                tooltip: 'Playlist / Queue (Ctrl+L)',
                                                icon: CupertinoIcons.list_bullet,
                                                size: 18,
                                                onTap: () => windowNotifier.togglePlaylist(),
                                              ),

                                              const SizedBox(width: 4),

                                              // Fullscreen Toggle
                                              _iconButton(
                                                tooltip: windowState.isFullscreen ? 'Exit Fullscreen (Esc)' : 'Fullscreen (F)',
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
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}
