import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<bool>? onSeekStartEnd;

  const CustomSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.buffer,
    required this.onSeek,
    this.onSeekStartEnd,
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
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Hover Timestamp Tooltip
                if (_isHovering && totalMs > 0 && !_isDragging)
                  Positioned(
                    bottom: 16,
                    left: (_hoverPositionFraction * width - 28).clamp(0.0, width - 56),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatDuration(
                          Duration(milliseconds: (_hoverPositionFraction * totalMs).round()),
                        ),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),

                // Track Container
                Container(
                  height: 24, // Touch target
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: (_isHovering || _isDragging) ? 7.0 : 4.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Buffered Bar
                        FractionallySizedBox(
                          widthFactor: bufferProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // Played Progress Bar
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: (_isHovering || _isDragging)
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accent.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
