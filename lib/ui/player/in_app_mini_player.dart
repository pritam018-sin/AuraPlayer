import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';

class InAppMiniPlayer extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const InAppMiniPlayer({
    super.key,
    required this.playerWrapper,
  });

  @override
  ConsumerState<InAppMiniPlayer> createState() => _InAppMiniPlayerState();
}

class _InAppMiniPlayerState extends ConsumerState<InAppMiniPlayer> {
  bool _isHovered = false;

  // Free continuous width adjustment (YouTube style)
  double _currentWidth = 360.0;

  // Custom dragged position (null means default bottom-right docked)
  Offset? _customOffset;

  void _expandToFullPlayer() {
    ref.read(activeTabProvider.notifier).setTab(AuraTab.player);
  }

  void _handleResize(DragUpdateDetails details, Size screenSize) {
    setState(() {
      // Pulling top-left outward (negative dx/dy) increases size
      // Pulling inward (positive dx/dy) decreases size
      final delta = -details.delta.dx;
      final maxW = (screenSize.width * 0.70).clamp(380.0, 750.0);
      final newWidth = (_currentWidth + delta).clamp(220.0, maxW);
      final widthDiff = newWidth - _currentWidth;
      _currentWidth = newWidth;

      // Keep bottom-right corner anchored in place while pulling top-left
      if (_customOffset != null) {
        _customOffset = Offset(
          _customOffset!.dx - widthDiff,
          _customOffset!.dy - (widthDiff / (16.0 / 9.0)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentHeight = _currentWidth / (16.0 / 9.0);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isPlaying = widget.playerWrapper.player.state.playing;
    final position = widget.playerWrapper.player.state.position;
    final duration = widget.playerWrapper.player.state.duration;

    final title = widget.playerWrapper.currentTitle ??
        (widget.playerWrapper.isLiveStream ? 'Live Stream' : 'Playing Video');

    // Calculate position
    double left = _customOffset != null
        ? _customOffset!.dx
        : (screenSize.width - _currentWidth - 24);
    double top = _customOffset != null
        ? _customOffset!.dy
        : (screenSize.height - currentHeight - 24);

    // Keep within bounds
    left = left.clamp(16.0, screenSize.width - _currentWidth - 16.0);
    top = top.clamp(60.0, screenSize.height - currentHeight - 16.0);

    final progressRatio = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      left: left,
      top: top,
      width: _currentWidth,
      height: currentHeight,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppTheme.accent.withValues(alpha: 0.55)
                  : const Color(0xFF0284C7).withValues(alpha: 0.70),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: (isDark ? AppTheme.accent : const Color(0xFF0284C7))
                    .withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Live Video Surface
                Video(
                  controller: widget.playerWrapper.videoController,
                  controls: NoVideoControls,
                  subtitleViewConfiguration: widget.playerWrapper.subtitleViewConfiguration,
                ),

                // 2. Gesture Detector for Body: Move by dragging, expand on tap
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _expandToFullPlayer,
                  onPanUpdate: (details) {
                    setState(() {
                      _customOffset = Offset(left + details.delta.dx, top + details.delta.dy);
                    });
                  },
                ),

                // 3. Hover Controls Overlay (YouTube Miniplayer style)
                IgnorePointer(
                  ignoring: !_isHovered,
                  child: AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Bar: Move drag handle, Title, Expand, Close
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 6, 0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Expand to Full Player Button
                                _controlIcon(
                                  tooltip: 'Expand to Cinema Player',
                                  icon: Icons.open_in_full_rounded,
                                  onTap: _expandToFullPlayer,
                                ),

                                // Stop & Close Button
                                _controlIcon(
                                  tooltip: 'Close / Stop Media',
                                  icon: Icons.close_rounded,
                                  iconColor: Colors.redAccent,
                                  onTap: () {
                                    ref.read(playlistProvider.notifier).stopAndClose();
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Center Controls: Quick Replay 10s, Hero Play/Pause, Forward 10s
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _centerHeroButton(
                                icon: Icons.replay_10_rounded,
                                size: 19,
                                onTap: () {
                                  widget.playerWrapper.seekRelative(const Duration(seconds: -10));
                                },
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    widget.playerWrapper.playOrPause();
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              _centerHeroButton(
                                icon: Icons.forward_10_rounded,
                                size: 19,
                                onTap: () {
                                  widget.playerWrapper.seekRelative(const Duration(seconds: 10));
                                },
                              ),
                            ],
                          ),

                          // Bottom Timeline Progress Bar
                          Container(
                            height: 3,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.15),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressRatio,
                              child: Container(
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Free Resize Handle at Top-Left Corner (YouTube Style)
                Positioned(
                  top: 0,
                  left: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => _handleResize(details, screenSize),
                      child: Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        color: Colors.transparent,
                        child: AnimatedOpacity(
                          opacity: _isHovered ? 0.9 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.7),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.north_west_rounded,
                                size: 14,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Left Border Resize Strip (Continuous Free Width Resize)
                Positioned(
                  top: 32,
                  left: 0,
                  bottom: 0,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => _handleResize(details, screenSize),
                    ),
                  ),
                ),

                // 6. Top Border Resize Strip (Continuous Free Height/Width Resize)
                Positioned(
                  top: 0,
                  left: 32,
                  right: 32,
                  height: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => _handleResize(details, screenSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlIcon({
    required String tooltip,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: iconColor ?? Colors.white70),
        ),
      ),
    );
  }

  Widget _centerHeroButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}
