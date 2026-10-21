import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<bool>? onSeekStartEnd;
  final bool isLive;

  const CustomSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.buffer,
    required this.onSeek,
    this.onSeekStartEnd,
    this.isLive = false,
  });

  @override
  State<CustomSeekBar> createState() => _CustomSeekBarState();
}

class _CustomSeekBarState extends State<CustomSeekBar> {
  bool _isHovering = false;
  bool _isDragging = false;
  double _hoverPositionFraction = 0.0;
  double _dragPositionFraction = 0.0;

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
    if (widget.isLive) {
      return _buildLiveBar();
    }

    final totalMs = widget.duration.inMilliseconds.toDouble();
    final currentMs = _isDragging
        ? _dragPositionFraction * totalMs
        : widget.position.inMilliseconds.toDouble();
    final bufferMs = widget.buffer.inMilliseconds.toDouble();

    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final bufferProgress = totalMs > 0 ? (bufferMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const thumbRadius = 8.0;
        const activeThumbRadius = 9.5;
        final currentThumbRadius = (_isHovering || _isDragging) ? activeThumbRadius : thumbRadius;

        // Position of radio button thumb
        final thumbCenterDx = progress * width;
        final thumbLeft = (thumbCenterDx - currentThumbRadius).clamp(0.0, width - 2 * currentThumbRadius);

        final tooltipFraction = _isDragging ? _dragPositionFraction : _hoverPositionFraction;
        final tooltipMs = (tooltipFraction * totalMs).round();
        final tooltipLeft = (tooltipFraction * width - 30).clamp(4.0, width - 64.0);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          onHover: (event) {
            setState(() {
              _hoverPositionFraction = (event.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              setState(() {
                _isDragging = true;
                _dragPositionFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
              });
              widget.onSeekStartEnd?.call(true);
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragPositionFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
              });
            },
            onHorizontalDragEnd: (details) {
              final targetMs = (_dragPositionFraction * totalMs).round();
              widget.onSeek(Duration(milliseconds: targetMs));
              setState(() => _isDragging = false);
              widget.onSeekStartEnd?.call(false);
            },
            onTapDown: (details) {
              final frac = (details.localPosition.dx / width).clamp(0.0, 1.0);
              final targetMs = (frac * totalMs).round();
              widget.onSeek(Duration(milliseconds: targetMs));
            },
            child: SizedBox(
              height: 28, // Generous hit box
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Hover / Drag Timestamp Tooltip
                  if ((_isHovering || _isDragging) && totalMs > 0)
                    Positioned(
                      bottom: 24,
                      left: tooltipLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181F),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.glassBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatDuration(Duration(milliseconds: tooltipMs)),
                          style: AppTheme.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                  // Background & Progress Track
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      height: (_isHovering || _isDragging) ? 8.0 : 6.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Buffered Bar
                          FractionallySizedBox(
                            widthFactor: bufferProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          // Played Progress Bar
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE11D48), Color(0xFFFA2D48)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Draggable Circular "Radio Button" Thumb Handle
                  Positioned(
                    left: thumbLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: currentThumbRadius * 2,
                      height: currentThumbRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.accent,
                          width: (_isHovering || _isDragging) ? 4.0 : 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.75),
                            blurRadius: (_isHovering || _isDragging) ? 12 : 8,
                            spreadRadius: (_isHovering || _isDragging) ? 2 : 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE BROADCAST',
                  style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: 0.8),
                    AppTheme.accentCyan.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Synchronized HLS Feed',
            style: AppTheme.caption.copyWith(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
