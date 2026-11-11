import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';

class CustomTitleBar extends ConsumerStatefulWidget {
  final String? title;
  final bool isVisible;

  const CustomTitleBar({
    super.key,
    this.title,
    this.isVisible = true,
  });

  @override
  ConsumerState<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends ConsumerState<CustomTitleBar> {
  bool _isHoveringTraffic = false;

  @override
  Widget build(BuildContext context) {
    final windowState = ref.watch(windowControlsProvider);
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surface.withValues(alpha: 0.40)
                    : Colors.white.withValues(alpha: 0.60),
                border: Border(
                  bottom: BorderSide(
                    color: borderCol,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Apple Traffic Lights
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringTraffic = true),
                    onExit: (_) => setState(() => _isHoveringTraffic = false),
                    child: Row(
                      children: [
                        _trafficButton(
                          color: AppTheme.trafficRed,
                          hoverIcon: Icons.close_rounded,
                          onTap: () => windowManager.close(),
                        ),
                        const SizedBox(width: 8),
                        _trafficButton(
                          color: AppTheme.trafficYellow,
                          hoverIcon: Icons.remove_rounded,
                          onTap: () => windowManager.minimize(),
                        ),
                        const SizedBox(width: 8),
                        _trafficButton(
                          color: AppTheme.trafficGreen,
                          hoverIcon: Icons.add_rounded,
                          onTap: () async {
                            if (await windowManager.isMaximized()) {
                              windowManager.unmaximize();
                            } else {
                              windowManager.maximize();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Draggable Title Area
                  Expanded(
                    child: DragToMoveArea(
                      child: GestureDetector(
                        onDoubleTap: () async {
                          if (await windowManager.isMaximized()) {
                            windowManager.unmaximize();
                          } else {
                            windowManager.maximize();
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Text(
                            widget.title ?? 'AuraPlayer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.title != null ? textPrimary : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Actions: PiP, Always on top, Playlist
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(
                        tooltip: 'Playlist',
                        icon: Icons.queue_music_rounded,
                        isActive: windowState.isPlaylistOpen,
                        onTap: () => windowNotifier.togglePlaylist(),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        tooltip: windowState.isAlwaysOnTop ? 'Unpin' : 'Always on Top',
                        icon: Icons.push_pin_rounded,
                        isActive: windowState.isAlwaysOnTop,
                        onTap: () => windowNotifier.toggleAlwaysOnTop(),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP)',
                        icon: Icons.picture_in_picture_alt_rounded,
                        isActive: windowState.isMiniMode,
                        onTap: () => windowNotifier.toggleMiniMode(),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        tooltip: windowState.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen (F)',
                        icon: windowState.isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        isActive: windowState.isFullscreen,
                        onTap: () => windowNotifier.toggleFullscreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trafficButton({
    required Color color,
    required IconData hoverIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12.5,
        height: 12.5,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isHoveringTraffic ? 0.9 : 0.0,
            child: Icon(
              hoverIcon,
              size: 8,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isActive ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
