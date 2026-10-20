import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../player/player_controller.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../modals/media_info_modal.dart';
import '../modals/open_network_modal.dart';
import '../modals/shortcuts_guide_modal.dart';
import '../modals/video_adjustments_modal.dart';
import '../player/audio_sub_sheet.dart';

class ModernMenuBar extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;
  final bool isVisible;

  const ModernMenuBar({
    super.key,
    required this.playerWrapper,
    this.isVisible = true,
  });

  @override
  ConsumerState<ModernMenuBar> createState() => _ModernMenuBarState();
}

class _ModernMenuBarState extends ConsumerState<ModernMenuBar> {
  bool _isHoveringTraffic = false;

  Future<void> _openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ref.read(playlistProvider.notifier).setList([
        PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
      ]);
    }
  }

  Future<void> _openMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
      allowMultiple: true,
    );
    if (result != null && result.paths.isNotEmpty) {
      final items = result.paths
          .whereType<String>()
          .map((p) => PlaylistItem(path: p, title: p.split(RegExp(r'[/\\]')).last))
          .toList();
      ref.read(playlistProvider.notifier).setList(items);
    }
  }

  Future<void> _openFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      final dir = Directory(path);
      final videoExts = ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv'];
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => videoExts.any((ext) => f.path.toLowerCase().endsWith(ext)))
          .map((f) => PlaylistItem(path: f.path, title: f.path.split(RegExp(r'[/\\]')).last))
          .toList();

      if (files.isNotEmpty) {
        ref.read(playlistProvider.notifier).setList(files);
      }
    }
  }

  void _showSnapshotFeedback(String? savedPath) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedPath != null ? 'Snapshot saved: ${savedPath.split(RegExp(r'[/\\]')).last}' : 'Failed to capture snapshot',
          style: AppTheme.bodySmall,
        ),
        backgroundColor: AppTheme.surfaceSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final windowState = ref.watch(windowControlsProvider);
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final playlist = ref.watch(playlistProvider);
    final playlistNotifier = ref.read(playlistProvider.notifier);
    final storage = ref.watch(storageServiceProvider);
    final recents = storage.getRecentFiles();

    final title = widget.playerWrapper.currentTitle ?? 'AuraPlayer';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.82),
            border: const Border(
              bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5),
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

              const SizedBox(width: 14),

              // VLC-Style Menus
              // MEDIA MENU
              _menuButton(
                label: 'Media',
                items: [
                  _menuItem('Open File...', 'Ctrl+O', _openFile),
                  _menuItem('Open Multiple Files...', '', _openMultipleFiles),
                  _menuItem('Open Folder...', 'Ctrl+F', _openFolder),
                  _menuItem('Open Network Stream...', 'Ctrl+N', () => OpenNetworkModal.show(context)),
                  const PopupMenuDivider(height: 1),
                  if (recents.isNotEmpty)
                    _menuItem('Recent Files (${recents.length})', '', () {
                      _showRecentMediaSheet(context, recents);
                    }),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Quit', 'Ctrl+Q', () => exit(0)),
                ],
              ),

              // PLAYBACK MENU
              _menuButton(
                label: 'Playback',
                items: [
                  _menuItem('Play / Pause', 'Space', () => widget.playerWrapper.playOrPause()),
                  _menuItem('Stop', 'S', () => widget.playerWrapper.stop()),
                  _menuItem('Previous Track', 'P', playlist.hasPrev ? () => playlistNotifier.prev() : null),
                  _menuItem('Next Track', 'N', playlist.hasNext ? () => playlistNotifier.next() : null),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Jump Forward 5s', 'Right', () => widget.playerWrapper.seekRelative(const Duration(seconds: 5))),
                  _menuItem('Jump Backward 5s', 'Left', () => widget.playerWrapper.seekRelative(const Duration(seconds: -5))),
                  _menuItem('Jump Forward 30s', 'Shift+Right', () => widget.playerWrapper.seekRelative(const Duration(seconds: 30))),
                  _menuItem('Jump Backward 30s', 'Shift+Left', () => widget.playerWrapper.seekRelative(const Duration(seconds: -30))),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Speed: Normal (1.0x)', '', () => widget.playerWrapper.setRate(1.0)),
                  _menuItem('Speed: Faster (1.5x)', '', () => widget.playerWrapper.setRate(1.5)),
                  _menuItem('Speed: 2x', '', () => widget.playerWrapper.setRate(2.0)),
                  _menuItem('Speed: Slower (0.75x)', '', () => widget.playerWrapper.setRate(0.75)),
                ],
              ),

              // AUDIO MENU
              _menuButton(
                label: 'Audio',
                items: [
                  _menuItem('Audio Tracks...', '', () => AudioSubtitleSheet.show(context, widget.playerWrapper)),
                  _menuItem('Mute / Unmute', 'M', () => widget.playerWrapper.toggleMute()),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Volume Up +5%', 'Up', () => widget.playerWrapper.changeVolumeRelative(5.0)),
                  _menuItem('Volume Down -5%', 'Down', () => widget.playerWrapper.changeVolumeRelative(-5.0)),
                  _menuItem('Volume 100%', '', () => widget.playerWrapper.setVolume(100.0)),
                  _menuItem('Volume Boost 125%', '', () => widget.playerWrapper.setVolume(125.0)),
                  _menuItem('Volume Boost 150%', '', () => widget.playerWrapper.setVolume(150.0)),
                ],
              ),

              // VIDEO MENU
              _menuButton(
                label: 'Video',
                items: [
                  _menuItem('Toggle Fullscreen', 'F', () => windowNotifier.toggleFullscreen()),
                  _menuItem('Always on Top', '', () => windowNotifier.toggleAlwaysOnTop()),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Aspect Ratio: Default', '', () => widget.playerWrapper.setAspectRatio('default')),
                  _menuItem('Aspect Ratio: 16:9', '', () => widget.playerWrapper.setAspectRatio('16:9')),
                  _menuItem('Aspect Ratio: 4:3', '', () => widget.playerWrapper.setAspectRatio('4:3')),
                  _menuItem('Aspect Ratio: 21:9', '', () => widget.playerWrapper.setAspectRatio('21:9')),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Take Snapshot', 'Shift+S', () async {
                    final path = await widget.playerWrapper.takeSnapshot();
                    _showSnapshotFeedback(path);
                  }),
                  _menuItem('Video Adjustments & Filters...', '', () => VideoAdjustmentsModal.show(context, widget.playerWrapper)),
                ],
              ),

              // SUBTITLE MENU
              _menuButton(
                label: 'Subtitle',
                items: [
                  _menuItem('Subtitles Track...', '', () => AudioSubtitleSheet.show(context, widget.playerWrapper)),
                  _menuItem('Add Subtitle File...', '', () => AudioSubtitleSheet.show(context, widget.playerWrapper)),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Delay +100ms', '', () => widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: 100))),
                  _menuItem('Delay -100ms', '', () => widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: -100))),
                  _menuItem('Reset Delay', '', () => widget.playerWrapper.subtitleDelay = Duration.zero),
                ],
              ),

              // TOOLS MENU
              _menuButton(
                label: 'Tools',
                items: [
                  _menuItem('Media Information & Codecs', 'Ctrl+I', () => MediaInfoModal.show(context, widget.playerWrapper)),
                  _menuItem('Effects and Filters', '', () => VideoAdjustmentsModal.show(context, widget.playerWrapper)),
                  _menuItem('Playlist Queue', 'Ctrl+L', () => windowNotifier.togglePlaylist()),
                ],
              ),

              // HELP MENU
              _menuButton(
                label: 'Help',
                items: [
                  _menuItem('Keyboard & Mouse Shortcuts', '', () => ShortcutsGuideModal.show(context)),
                  const PopupMenuDivider(height: 1),
                  _menuItem('About AuraPlayer', '', () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AuraPlayer',
                      applicationVersion: '1.0.0 (Windows Native Direct3D)',
                      applicationIcon: const Icon(CupertinoIcons.play_circle_fill, size: 36, color: AppTheme.accent),
                      children: const [
                        Text('Modern Apple-inspired media player with native libmpv hardware playback engine.'),
                      ],
                    );
                  }),
                ],
              ),

              const SizedBox(width: 8),

              // Draggable Window Title Area
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: widget.playerWrapper.currentTitle != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Quick Action Icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quickActionIcon(
                    tooltip: 'Snapshot (Shift+S)',
                    icon: CupertinoIcons.camera_fill,
                    onTap: () async {
                      final path = await widget.playerWrapper.takeSnapshot();
                      _showSnapshotFeedback(path);
                    },
                  ),
                  const SizedBox(width: 4),
                  _quickActionIcon(
                    tooltip: 'Media Info (Ctrl+I)',
                    icon: CupertinoIcons.info,
                    onTap: () => MediaInfoModal.show(context, widget.playerWrapper),
                  ),
                  const SizedBox(width: 4),
                  _quickActionIcon(
                    tooltip: 'Playlist (Ctrl+L)',
                    icon: CupertinoIcons.list_bullet,
                    isActive: windowState.isPlaylistOpen,
                    onTap: () => windowNotifier.togglePlaylist(),
                  ),
                  const SizedBox(width: 4),
                  _quickActionIcon(
                    tooltip: windowState.isAlwaysOnTop ? 'Unpin' : 'Always on Top',
                    icon: CupertinoIcons.pin_fill,
                    isActive: windowState.isAlwaysOnTop,
                    onTap: () => windowNotifier.toggleAlwaysOnTop(),
                  ),
                  const SizedBox(width: 4),
                  _quickActionIcon(
                    tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP)',
                    icon: CupertinoIcons.rectangle_on_rectangle,
                    isActive: windowState.isMiniMode,
                    onTap: () => windowNotifier.toggleMiniMode(),
                  ),
                  const SizedBox(width: 4),
                  _quickActionIcon(
                    tooltip: windowState.isFullscreen ? 'Exit Fullscreen (Esc)' : 'Fullscreen (F)',
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

  void _showRecentMediaSheet(BuildContext context, List<RecentItem> recents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Media Files', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: recents.length,
                separatorBuilder: (_, index) => const Divider(color: AppTheme.glassBorder, height: 1),
                itemBuilder: (context, index) {
                  final item = recents[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(CupertinoIcons.film, size: 18, color: AppTheme.accent),
                    title: Text(item.title, style: AppTheme.bodySmall),
                    subtitle: Text(item.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.caption),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(playlistProvider.notifier).setList([
                        PlaylistItem(path: item.path, title: item.title),
                      ]);
                    },
                  );
                },
              ),
            ),
          ],
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

  Widget _menuButton({required String label, required List<PopupMenuEntry> items}) {
    return PopupMenuButton(
      tooltip: '',
      offset: const Offset(0, 32),
      color: AppTheme.surface.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  PopupMenuItem _menuItem(String title, String shortcut, VoidCallback? onTap) {
    return PopupMenuItem(
      height: 32,
      onTap: onTap,
      enabled: onTap != null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.bodySmall.copyWith(fontSize: 12.5)),
          if (shortcut.isNotEmpty) ...[
            const SizedBox(width: 24),
            Text(shortcut, style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _quickActionIcon({
    required String tooltip,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
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
