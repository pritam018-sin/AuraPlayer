import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';

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

    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        border: const Border(
          left: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.list_bullet, size: 18, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Playlist (${playlist.items.length})',
                        style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Add files',
                        icon: const Icon(CupertinoIcons.plus_circle, size: 18, color: AppTheme.textPrimary),
                        onPressed: () => _addVideos(ref),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(CupertinoIcons.clear, size: 16, color: AppTheme.textSecondary),
                        onPressed: () => windowNotifier.closePlaylist(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.glassBorder, height: 1),

            // Playlist items
            Expanded(
              child: playlist.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.film, size: 40, color: AppTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text('No videos in queue', style: AppTheme.caption),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => _addVideos(ref),
                            icon: const Icon(CupertinoIcons.plus, size: 14),
                            label: const Text('Add Videos'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: playlist.items.length,
                      separatorBuilder: (_, index) => const Divider(color: AppTheme.glassBorder, height: 1),
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        final isPlaying = index == playlist.currentIndex;

                        return Container(
                          color: isPlaying ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Icon(
                              isPlaying ? CupertinoIcons.play_arrow_solid : CupertinoIcons.film,
                              size: 16,
                              color: isPlaying ? AppTheme.accent : AppTheme.textSecondary,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodySmall.copyWith(
                                color: isPlaying ? AppTheme.accent : AppTheme.textPrimary,
                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(CupertinoIcons.trash, size: 14, color: AppTheme.textTertiary),
                              onPressed: () => notifier.removeItem(index),
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
    );
  }
}
