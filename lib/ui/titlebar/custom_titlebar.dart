import 'package:flutter/cupertino.dart';
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.75),
            border: const Border(
              bottom: BorderSide(
                color: AppTheme.glassBorder,
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
                      hoverIcon: CupertinoIcons.clear,
                      onTap: () => windowManager.close(),
                    ),
                    const SizedBox(width: 8),
                    _trafficButton(
                      color: AppTheme.trafficYellow,
                      hoverIcon: CupertinoIcons.minus,
                      onTap: () => windowManager.minimize(),
                    ),
                    const SizedBox(width: 8),
                    _trafficButton(
                      color: AppTheme.trafficGreen,
                      hoverIcon: CupertinoIcons.plus,
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
                          fontWeight: FontWeight.w500,
                          color: widget.title != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
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
                    icon: CupertinoIcons.list_bullet,
                    isActive: windowState.isPlaylistOpen,
                    onTap: () => windowNotifier.togglePlaylist(),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    tooltip: windowState.isAlwaysOnTop ? 'Unpin' : 'Always on Top',
                    icon: CupertinoIcons.pin_fill,
                    isActive: windowState.isAlwaysOnTop,
                    onTap: () => windowNotifier.toggleAlwaysOnTop(),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP)',
                    icon: CupertinoIcons.rectangle_on_rectangle,
                    isActive: windowState.isMiniMode,
                    onTap: () => windowNotifier.toggleMiniMode(),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    tooltip: windowState.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen (F)',
                    icon: windowState.isFullscreen
                        ? CupertinoIcons.fullscreen_exit
                        : CupertinoIcons.fullscreen,
                    isActive: windowState.isFullscreen,
                    onTap: () => windowNotifier.toggleFullscreen(),
                  ),
                ],
              ),
            ],
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
