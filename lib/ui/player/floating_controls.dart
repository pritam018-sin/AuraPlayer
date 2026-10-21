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
  bool _showRemainingTime = false;

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
                            final timeDisplay = isLive
                                ? '● LIVE'
                                : (_showRemainingTime
                                    ? '-${_formatDuration(duration - position)} / ${_formatDuration(duration)}'
                                    : '${_formatDuration(position)} / ${_formatDuration(duration)}');

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              opacity: widget.isVisible ? 1.0 : 0.0,
                              child: IgnorePointer(
                                ignoring: !widget.isVisible,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: FrostedGlass(
                                    borderRadius: 20,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    fillColor: AppTheme.controlPillFill,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Seek Bar with draggable radio button thumb and live indicator
                                        CustomSeekBar(
                                          position: position,
                                          duration: duration,
                                          buffer: buffer,
                                          isLive: isLive,
                                          onSeek: (pos) => widget.playerWrapper.seek(pos),
                                        ),

                                        const SizedBox(height: 6),

                                        // Controls Row
                                        Row(
                                          children: [
                                            // Previous Track
                                            _iconButton(
                                              tooltip: 'Previous (P)',
                                              icon: CupertinoIcons.backward_fill,
                                              size: 15,
                                              enabled: playlist.hasPrev,
                                              onTap: () => playlistNotifier.prev(),
                                            ),
                                            const SizedBox(width: 2),

                                            // Replay 5s
                                            _iconButton(
                                              tooltip: 'Rewind 5s (Left)',
                                              icon: CupertinoIcons.gobackward,
                                              size: 17,
                                              onTap: () => widget.playerWrapper
                                                  .seekRelative(const Duration(seconds: -5)),
                                            ),
                                            const SizedBox(width: 4),

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
                                            const SizedBox(width: 4),

                                            // Stop Button
                                            _iconButton(
                                              tooltip: 'Stop (S)',
                                              icon: CupertinoIcons.stop_fill,
                                              size: 15,
                                              onTap: () => widget.playerWrapper.stop(),
                                            ),
                                            const SizedBox(width: 2),

                                            // Forward 5s
                                            _iconButton(
                                              tooltip: 'Forward 5s (Right)',
                                              icon: CupertinoIcons.goforward,
                                              size: 17,
                                              onTap: () => widget.playerWrapper
                                                  .seekRelative(const Duration(seconds: 5)),
                                            ),
                                            const SizedBox(width: 2),

                                            // Next Track
                                            _iconButton(
                                              tooltip: 'Next (N)',
                                              icon: CupertinoIcons.forward_fill,
                                              size: 15,
                                              enabled: playlist.hasNext,
                                              onTap: () => playlistNotifier.next(),
                                            ),

                                            const SizedBox(width: 12),

                                            // Timestamps (Click to toggle elapsed vs remaining)
                                            InkWell(
                                              onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Text(
                                                  timeDisplay,
                                                  style: AppTheme.caption.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const Spacer(),

                                            // Volume Slider & Mute
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
                                                    size: 17,
                                                    onTap: () => widget.playerWrapper.toggleMute(),
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    curve: Curves.easeOutCubic,
                                                    width: _isHoveringVolume ? 120 : 0,
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
                                                                  fontSize: 10,
                                                                  color: volume > 100 ? Colors.orangeAccent : AppTheme.textSecondary,
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.surfaceSecondary,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppTheme.glassBorder),
                                                  ),
                                                  child: Text(
                                                    widget.playerWrapper.currentAspectRatio ?? 'Ratio',
                                                    style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.surfaceSecondary,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppTheme.glassBorder),
                                                  ),
                                                  child: Text(
                                                    '${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 2)}x',
                                                    style: AppTheme.caption.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                      color: rate != 1.0 ? AppTheme.accent : AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Audio & Subtitles
                                            _iconButton(
                                              tooltip: 'Audio & Subtitles',
                                              icon: CupertinoIcons.captions_bubble,
                                              size: 17,
                                              onTap: () => AudioSubtitleSheet.show(context, widget.playerWrapper),
                                            ),

                                            const SizedBox(width: 4),

                                            // Snapshot Button
                                            _iconButton(
                                              tooltip: 'Take Snapshot (Shift+S)',
                                              icon: CupertinoIcons.camera_fill,
                                              size: 16,
                                              onTap: () async {
                                                final path = await widget.playerWrapper.takeSnapshot();
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
                                            ),

                                            const SizedBox(width: 4),

                                            // Fullscreen Toggle
                                            _iconButton(
                                              tooltip: windowState.isFullscreen ? 'Exit Fullscreen (Esc)' : 'Fullscreen (F)',
                                              icon: windowState.isFullscreen
                                                  ? CupertinoIcons.fullscreen_exit
                                                  : CupertinoIcons.fullscreen,
                                              size: 17,
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
          padding: const EdgeInsets.all(6),
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
