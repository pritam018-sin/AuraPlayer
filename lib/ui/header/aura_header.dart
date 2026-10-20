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
import '../modals/about_modal.dart';
import '../modals/media_info_modal.dart';
import '../modals/open_network_modal.dart';
import '../modals/shortcuts_guide_modal.dart';
import '../modals/video_adjustments_modal.dart';
import '../player/audio_sub_sheet.dart';

class AuraHeader extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;
  final bool isVisible;

  const AuraHeader({
    super.key,
    required this.playerWrapper,
    this.isVisible = true,
  });

  @override
  ConsumerState<AuraHeader> createState() => _AuraHeaderState();
}

class _AuraHeaderState extends ConsumerState<AuraHeader> {
  bool _isCloseHovered = false;

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
      await ref.read(storageServiceProvider).addImportedFolder(path);
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

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);
    final activeTabNotifier = ref.read(activeTabProvider.notifier);
    final windowState = ref.watch(windowControlsProvider);
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final playlist = ref.watch(playlistProvider);
    final playlistNotifier = ref.read(playlistProvider.notifier);
    final hasActiveMedia = playlist.currentItem != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 14, right: 0),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.88),
            border: const Border(
              bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Aura Brand Logo & Title
              GestureDetector(
                onTap: () => AboutModal.show(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AURA',
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' PLAYER',
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // VLC Menu Dropdowns
              _menuButton(
                label: 'Media',
                items: [
                  _menuItem('Open File...', 'Ctrl+O', _openFile),
                  _menuItem('Open Multiple Files...', '', _openMultipleFiles),
                  _menuItem('Open Folder to Library...', 'Ctrl+F', _openFolder),
                  _menuItem('Open Network Stream...', 'Ctrl+N', () => OpenNetworkModal.show(context)),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Exit', 'Ctrl+Q', () => exit(0)),
                ],
              ),
              _menuButton(
                label: 'Playback',
                items: [
                  _menuItem('Play / Pause', 'Space', () => widget.playerWrapper.playOrPause()),
                  _menuItem('Stop', 'S', () => widget.playerWrapper.stop()),
                  _menuItem('Previous', 'P', playlist.hasPrev ? () => playlistNotifier.prev() : null),
                  _menuItem('Next', 'N', playlist.hasNext ? () => playlistNotifier.next() : null),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Speed: Normal (1.0x)', '', () => widget.playerWrapper.setRate(1.0)),
                  _menuItem('Speed: Faster (1.5x)', '', () => widget.playerWrapper.setRate(1.5)),
                  _menuItem('Speed: 2x', '', () => widget.playerWrapper.setRate(2.0)),
                  _menuItem('Speed: Slower (0.75x)', '', () => widget.playerWrapper.setRate(0.75)),
                ],
              ),
              _menuButton(
                label: 'Audio',
                items: [
                  _menuItem('Audio Tracks...', '', () => AudioSubtitleSheet.show(context, widget.playerWrapper)),
                  _menuItem('Mute / Unmute', 'M', () => widget.playerWrapper.toggleMute()),
                  const PopupMenuDivider(height: 1),
                  _menuItem('Volume 100%', '', () => widget.playerWrapper.setVolume(100.0)),
                  _menuItem('Volume Boost 125%', '', () => widget.playerWrapper.setVolume(125.0)),
                  _menuItem('Volume Boost 150%', '', () => widget.playerWrapper.setVolume(150.0)),
                ],
              ),
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
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved: ${path.split(RegExp(r'[/\\]')).last}')),
                      );
                    }
                  }),
                  _menuItem('Video Adjustments...', '', () => VideoAdjustmentsModal.show(context, widget.playerWrapper)),
                ],
              ),
              _menuButton(
                label: 'Tools',
                items: [
                  _menuItem('Media Information', 'Ctrl+I', () => MediaInfoModal.show(context, widget.playerWrapper)),
                  _menuItem('Shortcuts Guide', '', () => ShortcutsGuideModal.show(context)),
                  const PopupMenuDivider(height: 1),
                  _menuItem('About AuraPlayer...', '', () => AboutModal.show(context)),
                ],
              ),

              const SizedBox(width: 8),

              // Draggable Area + Centered Capsule Navigation Pills (Aura Style)
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasActiveMedia) ...[
                          _navPill(
                            icon: CupertinoIcons.play_circle_fill,
                            label: 'Now Playing',
                            isActive: activeTab == AuraTab.player,
                            onTap: () => activeTabNotifier.setTab(AuraTab.player),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _navPill(
                          icon: CupertinoIcons.folder_fill,
                          label: 'Library & Folders',
                          isActive: activeTab == AuraTab.library,
                          onTap: () => activeTabNotifier.setTab(AuraTab.library),
                        ),
                        const SizedBox(width: 6),
                        _navPill(
                          icon: CupertinoIcons.list_bullet,
                          label: 'Queue (${playlist.items.length})',
                          isActive: activeTab == AuraTab.playlist,
                          onTap: () => activeTabNotifier.setTab(AuraTab.playlist),
                        ),
                        const SizedBox(width: 6),
                        _navPill(
                          icon: CupertinoIcons.clock_fill,
                          label: 'History',
                          isActive: activeTab == AuraTab.history,
                          onTap: () => activeTabNotifier.setTab(AuraTab.history),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Window Action Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quickActionIcon(
                    tooltip: windowState.isAlwaysOnTop ? 'Unpin' : 'Always on Top',
                    icon: CupertinoIcons.pin_fill,
                    isActive: windowState.isAlwaysOnTop,
                    onTap: () => windowNotifier.toggleAlwaysOnTop(),
                  ),
                  _quickActionIcon(
                    tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP)',
                    icon: CupertinoIcons.rectangle_on_rectangle,
                    isActive: windowState.isMiniMode,
                    onTap: () => windowNotifier.toggleMiniMode(),
                  ),

                  const SizedBox(width: 6),

                  // Windows Native Titlebar Buttons (Minimize, Maximize, Close)
                  _windowsButton(
                    tooltip: 'Minimize',
                    child: const Icon(CupertinoIcons.minus, size: 14, color: AppTheme.textPrimary),
                    onTap: () => windowManager.minimize(),
                  ),
                  _windowsButton(
                    tooltip: 'Maximize',
                    child: const Icon(CupertinoIcons.square, size: 12, color: AppTheme.textPrimary),
                    onTap: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  MouseRegion(
                    onEnter: (_) => setState(() => _isCloseHovered = true),
                    onExit: (_) => setState(() => _isCloseHovered = false),
                    child: _windowsButton(
                      tooltip: 'Close',
                      hoverColor: const Color(0xFFE81123),
                      child: Icon(
                        CupertinoIcons.clear,
                        size: 14,
                        color: _isCloseHovered ? Colors.white : AppTheme.textPrimary,
                      ),
                      onTap: () => windowManager.close(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.auraGradient : null,
          color: isActive ? null : AppTheme.surfaceSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.3) : AppTheme.glassBorder,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({required String label, required List<PopupMenuEntry> items}) {
    return PopupMenuButton(
      tooltip: '',
      offset: const Offset(0, 34),
      color: AppTheme.surface.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
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
          Text(title, style: AppTheme.bodySmall.copyWith(fontSize: 12)),
          if (shortcut.isNotEmpty) ...[
            const SizedBox(width: 20),
            Text(shortcut, style: AppTheme.caption.copyWith(fontSize: 10.5, color: AppTheme.textTertiary)),
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
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? AppTheme.accent : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _windowsButton({
    required String tooltip,
    required Widget child,
    required VoidCallback onTap,
    Color? hoverColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor ?? Colors.white.withValues(alpha: 0.1),
        child: Container(
          width: 44,
          height: 48,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
