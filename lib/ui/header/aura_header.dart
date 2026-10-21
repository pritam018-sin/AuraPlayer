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
          height: 52,
          padding: const EdgeInsets.only(left: 14, right: 0),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A10).withValues(alpha: 0.92),
            border: const Border(
              bottom: BorderSide(color: AppTheme.glassBorder, width: 0.6),
            ),
          ),
          child: Row(
            children: [
              // 1. Left: Brand & Studio Hub
              GestureDetector(
                onTap: () => AboutModal.show(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AURA',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  fontSize: 12.5,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ' PLAYER',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0x3322D3EE),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0x6622D3EE), width: 0.6),
                                ),
                                child: Text(
                                  'PRO',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF22D3EE),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'D3D11 Engine • 4K HDR',
                            style: AppTheme.caption.copyWith(
                              fontSize: 9,
                              color: AppTheme.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Return to Library Button (when inside video mode)
              if (activeTab == AuraTab.player) ...[
                InkWell(
                  onTap: () => playlistNotifier.stopAndClose(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.arrow_left, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Library',
                          style: AppTheme.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Modern Consolidated "VLC Studio" Command Hub Button
              _vlcStudioButton(context, playlist, playlistNotifier, windowNotifier),

              const SizedBox(width: 12),

              // 2. Middle: Draggable Area + Centered Segmented Capsule Navigation Rail
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasActiveMedia) ...[
                            _navPill(
                              icon: CupertinoIcons.play_circle_fill,
                              label: 'Now Playing',
                              isActive: activeTab == AuraTab.player,
                              onTap: () => activeTabNotifier.setTab(AuraTab.player),
                            ),
                            const SizedBox(width: 4),
                          ],
                          _navPill(
                            icon: CupertinoIcons.film_fill,
                            label: 'Cinema',
                            isActive: activeTab == AuraTab.library,
                            onTap: () => activeTabNotifier.setTab(AuraTab.library),
                          ),
                          const SizedBox(width: 4),
                          _navPill(
                            icon: CupertinoIcons.tv_fill,
                            label: 'Live TV',
                            badge: 'LIVE',
                            isActive: activeTab == AuraTab.live,
                            onTap: () => activeTabNotifier.setTab(AuraTab.live),
                          ),
                          const SizedBox(width: 4),
                          _navPill(
                            icon: CupertinoIcons.list_bullet,
                            label: 'Up Next',
                            badge: playlist.items.isNotEmpty ? '${playlist.items.length}' : null,
                            isActive: activeTab == AuraTab.playlist,
                            onTap: () => activeTabNotifier.setTab(AuraTab.playlist),
                          ),
                          const SizedBox(width: 4),
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
              ),

              // 3. Right: Fast Import + Window Action Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fast Import Action Capsule
                  _importMenuButton(context),

                  const SizedBox(width: 6),

                  // Always on Top Toggle
                  _quickActionIcon(
                    tooltip: windowState.isAlwaysOnTop ? 'Unpin (Always on Top Active)' : 'Always on Top',
                    icon: CupertinoIcons.pin_fill,
                    isActive: windowState.isAlwaysOnTop,
                    onTap: () => windowNotifier.toggleAlwaysOnTop(),
                  ),

                  // Mini Player PiP Mode
                  _quickActionIcon(
                    tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP Mode)',
                    icon: CupertinoIcons.rectangle_on_rectangle,
                    isActive: windowState.isMiniMode,
                    onTap: () => windowNotifier.toggleMiniMode(),
                  ),

                  const SizedBox(width: 8),

                  // Windows Frameless Titlebar Controls (Minimize, Maximize, Close)
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
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.auraGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.45),
                    blurRadius: 12,
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
              color: isActive ? const Color(0xFF04131F) : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: isActive ? const Color(0xFF04131F) : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badge == 'LIVE'
                      ? const Color(0xFFEF4444)
                      : (isActive ? const Color(0xFF04131F).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge == 'LIVE') ...[
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      badge,
                      style: AppTheme.caption.copyWith(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: badge == 'LIVE' ? Colors.white : (isActive ? const Color(0xFF04131F) : Colors.white),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _vlcStudioButton(
    BuildContext context,
    PlaylistState playlist,
    PlaylistNotifier playlistNotifier,
    WindowControlsNotifier windowNotifier,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'VLC Studio Controls',
      offset: const Offset(0, 38),
      color: const Color(0xFF14141B).withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      onSelected: (val) async {
        switch (val) {
          case 'open_file':
            _openFile();
            break;
          case 'open_multiple':
            _openMultipleFiles();
            break;
          case 'open_folder':
            _openFolder();
            break;
          case 'open_url':
            OpenNetworkModal.show(context);
            break;
          case 'play_pause':
            widget.playerWrapper.playOrPause();
            break;
          case 'stop':
            playlistNotifier.stopAndClose();
            break;
          case 'prev':
            if (playlist.hasPrev) playlistNotifier.prev();
            break;
          case 'next':
            if (playlist.hasNext) playlistNotifier.next();
            break;
          case 'speed_1':
            widget.playerWrapper.setRate(1.0);
            break;
          case 'speed_15':
            widget.playerWrapper.setRate(1.5);
            break;
          case 'speed_2':
            widget.playerWrapper.setRate(2.0);
            break;
          case 'audio_sheet':
            AudioSubtitleSheet.show(context, widget.playerWrapper);
            break;
          case 'mute':
            widget.playerWrapper.toggleMute();
            break;
          case 'vol_100':
            widget.playerWrapper.setVolume(100.0);
            break;
          case 'vol_150':
            widget.playerWrapper.setVolume(150.0);
            break;
          case 'ratio_default':
            widget.playerWrapper.setAspectRatio('default');
            break;
          case 'ratio_16_9':
            widget.playerWrapper.setAspectRatio('16:9');
            break;
          case 'ratio_21_9':
            widget.playerWrapper.setAspectRatio('21:9');
            break;
          case 'adjustments':
            VideoAdjustmentsModal.show(context, widget.playerWrapper);
            break;
          case 'snapshot':
            final path = await widget.playerWrapper.takeSnapshot();
            if (context.mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved: ${path.split(RegExp(r'[/\\]')).last}')),
              );
            }
            break;
          case 'fullscreen':
            windowNotifier.toggleFullscreen();
            break;
          case 'media_info':
            MediaInfoModal.show(context, widget.playerWrapper);
            break;
          case 'shortcuts':
            ShortcutsGuideModal.show(context);
            break;
          case 'about':
            AboutModal.show(context);
            break;
          case 'exit':
            exit(0);
        }
      },
      itemBuilder: (ctx) => [
        // Section: Media & Playback
        _headerMenuItem('PLAYBACK & MEDIA'),
        _menuRow('play_pause', 'Play / Pause', 'Space', CupertinoIcons.play_arrow_solid),
        _menuRow('stop', 'Stop & Return to Library', 'S', CupertinoIcons.stop_fill),
        _menuRow('prev', 'Previous Video', 'P', CupertinoIcons.backward_fill),
        _menuRow('next', 'Next Video', 'N', CupertinoIcons.forward_fill),
        _menuRow('speed_15', 'Speed: Fast 1.5x', ']', CupertinoIcons.gauge),
        _menuRow('speed_2', 'Speed: 2.0x', '', CupertinoIcons.forward),
        const PopupMenuDivider(height: 1),

        // Section: Audio & Video
        _headerMenuItem('AUDIO & VIDEO TOOLS'),
        _menuRow('audio_sheet', 'Audio & Subtitle Tracks...', '', CupertinoIcons.captions_bubble_fill),
        _menuRow('vol_150', 'Volume Boost 150%', '', CupertinoIcons.volume_up),
        _menuRow('mute', 'Mute / Unmute', 'M', CupertinoIcons.volume_off),
        _menuRow('ratio_16_9', 'Aspect Ratio: 16:9', '', CupertinoIcons.rectangle_split_3x1),
        _menuRow('ratio_21_9', 'Aspect Ratio: 21:9 Ultrawide', '', CupertinoIcons.rectangle_arrow_up_right_arrow_down_left),
        _menuRow('adjustments', 'Video Adjustments & Filters...', '', CupertinoIcons.slider_horizontal_3),
        _menuRow('snapshot', 'Take Snapshot / Frame Capture', 'Shift+S', CupertinoIcons.camera_fill),
        _menuRow('fullscreen', 'Toggle Fullscreen', 'F', CupertinoIcons.fullscreen),
        const PopupMenuDivider(height: 1),

        // Section: Media Inputs & System
        _headerMenuItem('SYSTEM & FILE INPUTS'),
        _menuRow('open_file', 'Open Video File...', 'Ctrl+O', CupertinoIcons.doc_fill),
        _menuRow('open_folder', 'Open Folder to Library...', 'Ctrl+F', CupertinoIcons.folder_fill),
        _menuRow('open_url', 'Open Network URL / IPTV...', 'Ctrl+N', CupertinoIcons.globe),
        _menuRow('media_info', 'Media & Codec Information', 'Ctrl+I', CupertinoIcons.info_circle_fill),
        _menuRow('shortcuts', 'Keyboard Shortcuts Guide', '', CupertinoIcons.keyboard),
        _menuRow('about', 'About AuraPlayer Studio', '', CupertinoIcons.sparkles),
        const PopupMenuDivider(height: 1),
        _menuRow('exit', 'Exit AuraPlayer', 'Ctrl+Q', CupertinoIcons.power),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.slider_horizontal_3, size: 13, color: AppTheme.accentCyan),
            const SizedBox(width: 5),
            Text(
              'Studio',
              style: AppTheme.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(CupertinoIcons.chevron_down, size: 9, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _headerMenuItem(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 24,
      child: Text(
        title,
        style: AppTheme.caption.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuRow(String value, String title, String shortcut, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(fontSize: 12),
            ),
          ),
          if (shortcut.isNotEmpty)
            Text(
              shortcut,
              style: AppTheme.caption.copyWith(fontSize: 10, color: AppTheme.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _importMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Import Video Media',
      offset: const Offset(0, 38),
      color: const Color(0xFF14141B).withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      onSelected: (val) {
        if (val == 'folder') _openFolder();
        if (val == 'file') _openFile();
        if (val == 'files') _openMultipleFiles();
        if (val == 'url') OpenNetworkModal.show(context);
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'folder',
          height: 34,
          child: Row(
            children: [
              Icon(CupertinoIcons.folder_badge_plus, size: 15, color: AppTheme.accent),
              SizedBox(width: 9),
              Text('Import Folder to Library...', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'file',
          height: 34,
          child: Row(
            children: [
              Icon(CupertinoIcons.doc_fill, size: 15, color: Colors.white70),
              SizedBox(width: 9),
              Text('Open Video File... (Ctrl+O)', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'files',
          height: 34,
          child: Row(
            children: [
              Icon(CupertinoIcons.doc_on_doc_fill, size: 15, color: Colors.white70),
              SizedBox(width: 9),
              Text('Open Multiple Files...', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'url',
          height: 34,
          child: Row(
            children: [
              Icon(CupertinoIcons.globe, size: 15, color: AppTheme.accentCyan),
              SizedBox(width: 9),
              Text('Open Network Stream (Ctrl+N)', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppTheme.auraGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.plus, size: 13, color: Color(0xFF04131F)),
            const SizedBox(width: 4),
            Text(
              'Add Media',
              style: AppTheme.caption.copyWith(
                color: const Color(0xFF04131F),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
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
          height: 52,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
