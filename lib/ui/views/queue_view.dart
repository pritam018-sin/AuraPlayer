import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  Future<void> _addVideos(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
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

  Future<void> _addFolder(WidgetRef ref) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await ref.read(storageServiceProvider).addImportedFolder(path);
      final dir = Directory(path);
      final videoExts = ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv'];
      final files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => videoExts.any((ext) => f.path.toLowerCase().endsWith(ext)))
          .map((f) => PlaylistItem(path: f.path, title: f.path.split(RegExp(r'[/\\]')).last))
          .toList();

      for (final item in files) {
        ref.read(playlistProvider.notifier).addItem(item);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);
    final notifier = ref.read(playlistProvider.notifier);

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Queue Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.65),
              border: const Border(
                bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppTheme.auraGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.list_bullet, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Playback Queue', style: AppTheme.headline),
                        const SizedBox(height: 2),
                        Text(
                          '${playlist.items.length} videos scheduled for playback',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (playlist.hasItems) ...[
                      TextButton.icon(
                        onPressed: () => notifier.playIndex(0),
                        icon: const Icon(CupertinoIcons.play_circle_fill, size: 16),
                        label: const Text('Play from Top'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          final items = [...playlist.items]..shuffle();
                          notifier.setList(items, initialIndex: 0);
                        },
                        icon: const Icon(CupertinoIcons.shuffle, size: 15),
                        label: const Text('Shuffle'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => notifier.setList([]),
                        icon: const Icon(CupertinoIcons.trash, size: 15),
                        label: const Text('Clear Queue'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textTertiary,
                          textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _addVideos(ref),
                      icon: const Icon(CupertinoIcons.plus, size: 15),
                      label: const Text('Add Files'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addFolder(ref),
                      icon: const Icon(CupertinoIcons.folder_badge_plus, size: 15),
                      label: const Text('Add Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: playlist.items.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surfaceSecondary,
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.square_stack_3d_down_dottedline,
                                  size: 32, color: AppTheme.textTertiary),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Queue is Empty', style: AppTheme.headline),
                          const SizedBox(height: 8),
                          Text(
                            'Add videos or an entire folder to queue them for continuous playback.',
                            textAlign: TextAlign.center,
                            style: AppTheme.caption,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _addVideos(ref),
                                icon: const Icon(CupertinoIcons.plus, size: 16),
                                label: const Text('Add Videos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.glassBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _addFolder(ref),
                                icon: const Icon(CupertinoIcons.folder_fill, size: 16),
                                label: const Text('Add Video Folder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    itemCount: playlist.items.length,
                    itemBuilder: (context, index) {
                      final item = playlist.items[index];
                      final isCurrent = index == playlist.currentIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FrostedGlass(
                          borderRadius: 12,
                          fillColor: isCurrent
                              ? AppTheme.accent.withValues(alpha: 0.12)
                              : AppTheme.surfaceSecondary.withValues(alpha: 0.45),
                          borderColor: isCurrent
                              ? AppTheme.accent.withValues(alpha: 0.5)
                              : AppTheme.glassBorder,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () => notifier.playIndex(index),
                          child: Row(
                            children: [
                              // Index or Playing indicator
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppTheme.accent : AppTheme.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: isCurrent
                                      ? const Icon(CupertinoIcons.play_arrow_solid, size: 16, color: Colors.white)
                                      : Text(
                                          '${index + 1}',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Title & Path
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: isCurrent ? AppTheme.accent : AppTheme.textPrimary,
                                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Play / Remove Buttons
                              IconButton(
                                tooltip: 'Play this video',
                                icon: Icon(
                                  isCurrent ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                  size: 16,
                                  color: isCurrent ? AppTheme.accent : AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  if (isCurrent) {
                                    ref.read(playerControllerProvider).playOrPause();
                                  } else {
                                    notifier.playIndex(index);
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Remove from Queue',
                                icon: const Icon(CupertinoIcons.trash, size: 15, color: AppTheme.textTertiary),
                                onPressed: () => notifier.removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
