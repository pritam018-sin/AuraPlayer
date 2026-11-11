import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../modals/add_from_library_modal.dart';

class PlaylistDrawer extends ConsumerWidget {
  const PlaylistDrawer({super.key});

  Future<void> _addVideos(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      for (final path in result.paths.whereType<String>()) {
        ref.read(playlistProvider.notifier).addItem(
              PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);
    final notifier = ref.read(playlistProvider.notifier);
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          width: 350,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.14),
                      const Color(0xFF070A12).withValues(alpha: 0.40),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.45),
                    ],
            ),
            border: Border(
              left: BorderSide(
                color: isDark ? const Color(0x45FFFFFF) : const Color(0x30000000),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 1. Drawer Header with Back Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0x30FFFFFF) : const Color(0x25000000),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Prominent, highly-visible Back Button
                      // Minimal Back Arrow Button (Icon only)
                      Tooltip(
                        message: 'Close Queue',
                        child: InkWell(
                          onTap: () => windowNotifier.closePlaylist(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Title
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 17,
                              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Queue (${playlist.items.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add from Library (+ Icon Button)
                      Tooltip(
                        message: 'Add Video from In-App Library',
                        child: InkWell(
                          onTap: () => AddFromLibraryModal.show(context, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Browse PC Files
                      Tooltip(
                        message: 'Browse PC Files',
                        child: IconButton(
                          icon: Icon(
                            Icons.folder_open_rounded,
                            size: 19,
                            color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                          ),
                          onPressed: () => _addVideos(ref),
                        ),
                      ),

                      // Clear Queue
                      if (playlist.items.length > 1)
                        Tooltip(
                          message: 'Clear Queue',
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF43F5E)),
                            onPressed: () {
                              notifier.clearQueue();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Queue cleared'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. Playlist Items
                Expanded(
                  child: playlist.items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0x20FFFFFF) : const Color(0x18000000),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.movie_rounded, size: 28, color: AppTheme.accent),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Queue is Empty',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add videos to play continuously',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => AddFromLibraryModal.show(context, ref),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Add from Library'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accent,
                                        foregroundColor: const Color(0xFF04131F),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _addVideos(ref),
                                      icon: const Icon(Icons.create_new_folder_rounded, size: 15),
                                      label: const Text('PC Files'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                        side: BorderSide(
                                          color: isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          itemCount: playlist.items.length,
                          itemBuilder: (context, index) {
                            final item = playlist.items[index];
                            final isPlaying = index == playlist.currentIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? AppTheme.accent.withValues(alpha: isDark ? 0.22 : 0.16)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.60)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPlaying
                                      ? AppTheme.accent
                                      : (isDark
                                          ? const Color(0x30FFFFFF)
                                          : const Color(0x22000000)),
                                  width: isPlaying ? 1.2 : 0.8,
                                ),
                                boxShadow: isPlaying
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accent.withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? AppTheme.accent
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.12)
                                            : Colors.black.withValues(alpha: 0.08)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isPlaying
                                        ? const Icon(Icons.play_arrow_rounded,
                                            size: 14, color: Color(0xFF04131F))
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isPlaying
                                        ? (isDark ? AppTheme.accent : const Color(0xFF0284C7))
                                        : (isDark ? Colors.white : AppTheme.lightTextPrimary),
                                    fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove from Queue',
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () {
                                    notifier.removeItem(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Removed ${item.title} from queue'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                                onTap: () => notifier.playIndex(index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
