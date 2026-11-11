import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../player/player_controller.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../modals/about_modal.dart';
import '../modals/open_network_modal.dart';
import '../modals/shortcuts_guide_modal.dart';
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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final hasActiveMedia = playlist.currentItem != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              height: 52,
              padding: const EdgeInsets.only(left: 14, right: 0),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A10).withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.60),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder,
                    width: 0.8,
                  ),
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
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                              ),
                              Text(
                                ' PLAYER',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
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

              const SizedBox(width: 8),

              // Modern Consolidated "VLC Studio" Command Hub Button
              _vlcStudioButton(context, playlist, playlistNotifier, windowNotifier, isDark),

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
                        color: isDark
                            ? const Color(0xFF13131A).withValues(alpha: 0.38)
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFF0F172A).withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.45)
                                : const Color(0xFF0F172A).withValues(alpha: 0.08),
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
                              icon: Icons.play_circle_fill_rounded,
                              label: 'Now Playing',
                              isActive: activeTab == AuraTab.player,
                              onTap: () => activeTabNotifier.setTab(AuraTab.player),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 4),
                          ],
                          _navPill(
                            icon: Icons.video_library_rounded,
                            label: 'Library',
                            isActive: activeTab == AuraTab.library,
                            onTap: () => activeTabNotifier.setTab(AuraTab.library),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _navPill(
                            icon: Icons.live_tv_rounded,
                            label: 'Live TV',
                            badge: 'LIVE',
                            isActive: activeTab == AuraTab.live,
                            onTap: () => activeTabNotifier.setTab(AuraTab.live),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _navPill(
                            icon: Icons.history_rounded,
                            label: 'History',
                            isActive: activeTab == AuraTab.history,
                            onTap: () => activeTabNotifier.setTab(AuraTab.history),
                            isDark: isDark,
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
                  _importMenuButton(context, isDark),

                  const SizedBox(width: 6),

                  // Always on Top Toggle
                  _quickActionIcon(
                    tooltip: windowState.isAlwaysOnTop ? 'Unpin (Always on Top Active)' : 'Always on Top',
                    icon: Icons.push_pin_rounded,
                    isActive: windowState.isAlwaysOnTop,
                    onTap: () => windowNotifier.toggleAlwaysOnTop(),
                    isDark: isDark,
                  ),

                  // Mini Player PiP Mode
                  _quickActionIcon(
                    tooltip: windowState.isMiniMode ? 'Standard Window' : 'Mini Player (PiP Mode)',
                    icon: Icons.picture_in_picture_alt_rounded,
                    isActive: windowState.isMiniMode,
                    onTap: () => windowNotifier.toggleMiniMode(),
                    isDark: isDark,
                  ),

                  // Dedicated Theme Mode Switcher (Clean Icon-only, no box background)
                  _quickActionIcon(
                    tooltip: isDark
                        ? 'Switch to Light Glass Theme'
                        : 'Switch to Dark Obsidian Glass Theme',
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    isActive: false,
                    isDark: isDark,
                    iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF0284C7),
                    onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),

                  const SizedBox(width: 8),

                  // Windows Frameless Titlebar Controls (Minimize, Maximize, Close)
                  _windowsButton(
                    tooltip: 'Minimize',
                    child: Icon(
                      Icons.remove_rounded,
                      size: 15,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
                    onTap: () => windowManager.minimize(),
                  ),
                  _windowsButton(
                    tooltip: 'Maximize',
                    child: Icon(
                      Icons.crop_square_rounded,
                      size: 14,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
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
                        Icons.close_rounded,
                        size: 15,
                        color: _isCloseHovered
                            ? Colors.white
                            : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
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
    bool isDark = true,
  }) {
    final inactiveColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final activeColor = Colors.white;
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
            color: isActive ? Colors.white.withValues(alpha: 0.35) : Colors.transparent,
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
              size: 15,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
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
                      : (isActive
                          ? const Color(0xFF04131F).withValues(alpha: 0.18)
                          : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))),
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
                        color: badge == 'LIVE' ? Colors.white : (isActive ? const Color(0xFF04131F) : inactiveColor),
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
    bool isDark,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'VLC Studio Controls',
      offset: const Offset(0, 38),
      color: isDark ? const Color(0xFF14141B).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder),
      ),
      onSelected: (val) async {
        switch (val) {
          case 'studio_hud':
            windowNotifier.toggleInspector();
            break;
          case 'vol_200':
            widget.playerWrapper.setVolume(200.0);
            break;
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
            windowNotifier.openInspector(tab: 0);
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
            windowNotifier.openInspector(tab: 3);
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
        _headerMenuItem('PRO STUDIO SUITE'),
        _menuRow('studio_hud', 'Cinema Studio Pro HUD (Full Suite)', 'I', Icons.tune_rounded, isDark),
        const PopupMenuDivider(height: 1),

        _headerMenuItem('PLAYBACK & MEDIA'),
        _menuRow('play_pause', 'Play / Pause', 'Space', Icons.play_arrow_rounded, isDark),
        _menuRow('stop', 'Stop & Return to Library', 'S', Icons.stop_rounded, isDark),
        _menuRow('prev', 'Previous Video', 'P', Icons.skip_previous_rounded, isDark),
        _menuRow('next', 'Next Video', 'N', Icons.skip_next_rounded, isDark),
        _menuRow('speed_15', 'Speed: Fast 1.5x', ']', Icons.speed_rounded, isDark),
        _menuRow('speed_2', 'Speed: 2.0x', '', Icons.fast_forward_rounded, isDark),
        const PopupMenuDivider(height: 1),

        _headerMenuItem('AUDIO & VIDEO TOOLS'),
        _menuRow('audio_sheet', 'Audio & Subtitle Tracks...', '', Icons.subtitles_rounded, isDark),
        _menuRow('vol_200', 'Volume Boost 200% (VLC Max)', '', Icons.volume_up_rounded, isDark),
        _menuRow('vol_150', 'Volume Boost 150%', '', Icons.volume_up_rounded, isDark),
        _menuRow('mute', 'Mute / Unmute', 'M', Icons.volume_off_rounded, isDark),
        _menuRow('ratio_16_9', 'Aspect Ratio: 16:9', '', Icons.aspect_ratio_rounded, isDark),
        _menuRow('ratio_21_9', 'Aspect Ratio: 21:9 Ultrawide', '', Icons.fullscreen_rounded, isDark),
        _menuRow('adjustments', 'Video Adjustments & Filters...', '', Icons.tune_rounded, isDark),
        _menuRow('snapshot', 'Take Snapshot / Frame Capture', 'Shift+S', Icons.camera_alt_rounded, isDark),
        _menuRow('fullscreen', 'Toggle Fullscreen', 'F', Icons.fullscreen_rounded, isDark),
        const PopupMenuDivider(height: 1),

        _headerMenuItem('SYSTEM & FILE INPUTS'),
        _menuRow('open_file', 'Open Video File...', 'Ctrl+O', Icons.video_file_rounded, isDark),
        _menuRow('open_folder', 'Open Folder to Library...', 'Ctrl+F', Icons.folder_rounded, isDark),
        _menuRow('open_url', 'Open Network URL / IPTV...', 'Ctrl+N', Icons.public_rounded, isDark),
        _menuRow('media_info', 'Media & Codec Information', 'Ctrl+I', Icons.info_outline_rounded, isDark),
        _menuRow('shortcuts', 'Keyboard Shortcuts Guide', '', Icons.keyboard_rounded, isDark),
        _menuRow('about', 'About AuraPlayer Studio', '', Icons.auto_awesome_rounded, isDark),
        const PopupMenuDivider(height: 1),
        _menuRow('exit', 'Exit AuraPlayer', 'Ctrl+Q', Icons.power_settings_new_rounded, isDark),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 14,
              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
            ),
            const SizedBox(width: 5),
            Text(
              'Studio',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isDark ? AppTheme.textTertiary : AppTheme.lightTextSecondary,
            ),
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

  PopupMenuItem<String> _menuRow(
    String value,
    String title,
    String shortcut,
    IconData icon,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon, size: 15, color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          if (shortcut.isNotEmpty)
            Text(
              shortcut,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppTheme.textTertiary : AppTheme.lightTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _importMenuButton(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Import Video Media',
      offset: const Offset(0, 38),
      color: isDark ? const Color(0xFF14141B).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder),
      ),
      onSelected: (val) {
        if (val == 'folder') _openFolder();
        if (val == 'file') _openFile();
        if (val == 'files') _openMultipleFiles();
        if (val == 'url') OpenNetworkModal.show(context);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'folder',
          height: 34,
          child: Row(
            children: [
              const Icon(Icons.create_new_folder_rounded, size: 15, color: AppTheme.accent),
              const SizedBox(width: 9),
              Text(
                'Import Folder to Library...',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'file',
          height: 34,
          child: Row(
            children: [
              Icon(Icons.video_file_rounded, size: 15, color: isDark ? Colors.white70 : AppTheme.lightTextSecondary),
              const SizedBox(width: 9),
              Text(
                'Open Video File... (Ctrl+O)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'files',
          height: 34,
          child: Row(
            children: [
              Icon(Icons.video_collection_rounded, size: 15, color: isDark ? Colors.white70 : AppTheme.lightTextSecondary),
              const SizedBox(width: 9),
              Text(
                'Open Multiple Files...',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'url',
          height: 34,
          child: Row(
            children: [
              const Icon(Icons.public_rounded, size: 15, color: AppTheme.accentCyan),
              const SizedBox(width: 9),
              Text(
                'Open Network Stream (Ctrl+N)',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : const Color(0xFFE0F2FE).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.accentCyan.withValues(alpha: 0.5) : const Color(0xFF0284C7).withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7)),
            const SizedBox(width: 4),
            Text(
              'Add Media',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
    bool isDark = true,
    Color? iconColor,
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
            size: 16,
            color: iconColor ??
                (isActive
                    ? AppTheme.accent
                    : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
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
