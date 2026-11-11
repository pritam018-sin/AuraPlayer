import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import 'audio_sub_sheet.dart';

class VideoGlassyMenu extends ConsumerStatefulWidget {
  final Offset position;
  final AuraPlayerWrapper playerWrapper;

  const VideoGlassyMenu({
    super.key,
    required this.position,
    required this.playerWrapper,
  });

  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required AuraPlayerWrapper playerWrapper,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Video Options',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, anim1, anim2) {
        return VideoGlassyMenu(
          position: position,
          playerWrapper: playerWrapper,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<VideoGlassyMenu> createState() => _VideoGlassyMenuState();
}

class _VideoGlassyMenuState extends ConsumerState<VideoGlassyMenu> {
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final List<String> _aspects = ['default', '16:9', '4:3', '21:9'];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final playlistNotifier = ref.read(playlistProvider.notifier);

    final currentRate = widget.playerWrapper.player.state.rate;
    final currentAspect = widget.playerWrapper.currentAspectRatio ?? 'default';
    final isPlaying = widget.playerWrapper.player.state.playing;

    const menuWidth = 320.0;
    const menuHeight = 460.0;

    // Boundary check so menu stays comfortably within window
    double left = widget.position.dx;
    double top = widget.position.dy;

    if (left + menuWidth > screenSize.width - 16) {
      left = screenSize.width - menuWidth - 16;
    }
    if (left < 16) left = 16;

    if (top + menuHeight > screenSize.height - 24) {
      top = screenSize.height - menuHeight - 24;
    }
    if (top < 16) top = 16;

    final bgGlassColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.90);

    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: bgGlassColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 16, color: AppTheme.accentCyan),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Options & Settings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: textSecondary,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close_rounded, size: 16, color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, thickness: 0.8, color: dividerColor),

                      // 1. Playback Speed Row with Direct Selection Pills
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.speed_rounded, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Speed',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                ),
                                const Spacer(),
                                Text(
                                  '${currentRate.toStringAsFixed(currentRate.truncateToDouble() == currentRate ? 0 : 2)}x',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _speeds.map((rate) {
                                  final isSelected = (currentRate - rate).abs() < 0.05;
                                  return _pillButton(
                                    label: '${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 2)}x',
                                    isSelected: isSelected,
                                    isDark: isDark,
                                    onTap: () {
                                      widget.playerWrapper.setRate(rate);
                                      setState(() {});
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, thickness: 0.8, color: dividerColor),

                      // 2. Aspect Ratio Row with Direct Selection Pills
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.aspect_ratio_rounded, size: 16, color: textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Aspect Ratio',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                ),
                                const Spacer(),
                                Text(
                                  currentAspect.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: _aspects.map((aspect) {
                                final isSelected = currentAspect.toLowerCase() == aspect.toLowerCase();
                                final label = aspect == 'default' ? 'Fit' : aspect;
                                return Expanded(
                                  child: _pillButton(
                                    label: label,
                                    isSelected: isSelected,
                                    isDark: isDark,
                                    onTap: () {
                                      widget.playerWrapper.setAspectRatio(aspect);
                                      setState(() {});
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, thickness: 0.8, color: dividerColor),

                      // 3. Action Menu Items
                      _menuItem(
                        icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        iconColor: AppTheme.accent,
                        title: isPlaying ? 'Pause Video' : 'Play Video',
                        shortcut: 'Space',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () {
                          widget.playerWrapper.playOrPause();
                          Navigator.of(context).pop();
                        },
                      ),

                      _menuItem(
                        icon: Icons.subtitles_rounded,
                        iconColor: textSecondary,
                        title: 'Audio & Subtitle Tracks...',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          AudioSubtitleSheet.show(context, widget.playerWrapper);
                        },
                      ),

                      _menuItem(
                        icon: Icons.tune_rounded,
                        iconColor: textSecondary,
                        title: 'Video Adjustments & Filters...',
                        shortcut: 'I',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          windowNotifier.openInspector(tab: 0);
                        },
                      ),

                      _menuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: textSecondary,
                        title: 'Media Information & Codecs',
                        shortcut: 'Ctrl+I',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          windowNotifier.openInspector(tab: 3);
                        },
                      ),

                      _menuItem(
                        icon: Icons.camera_alt_rounded,
                        iconColor: textSecondary,
                        title: 'Take Snapshot',
                        shortcut: 'Shift+S',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () async {
                          Navigator.of(context).pop();
                          final path = await widget.playerWrapper.takeSnapshot();
                          if (context.mounted && path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Snapshot saved: ${path.split(RegExp(r'[/\\]')).last}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),

                      _menuItem(
                        icon: Icons.video_library_rounded,
                        iconColor: AppTheme.accentCyan,
                        title: 'Browse Library (Mini Player)',
                        shortcut: 'L',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          ref.read(activeTabProvider.notifier).setTab(AuraTab.library);
                        },
                      ),

                      Divider(height: 1, thickness: 0.8, color: dividerColor),

                      // Danger item: Stop & Return to Library
                      _menuItem(
                        icon: Icons.stop_circle_rounded,
                        iconColor: Colors.redAccent,
                        title: 'Stop & Return to Library',
                        shortcut: 'S',
                        titleColor: Colors.redAccent,
                        textPrimary: Colors.redAccent,
                        textSecondary: Colors.redAccent.withValues(alpha: 0.7),
                        onTap: () {
                          Navigator.of(context).pop();
                          playlistNotifier.stopAndClose();
                        },
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: isDark ? 0.28 : 0.20)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.8)
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0284C7))
                  : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? shortcut,
    Color? titleColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppTheme.accent.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? textPrimary,
                ),
              ),
            ),
            if (shortcut != null) ...[
              Text(
                shortcut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
