import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';
import '../modals/add_from_library_modal.dart';
import '../modals/manage_folders_modal.dart';

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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.35);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Queue Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surface.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.38),
              border: Border(
                bottom: BorderSide(color: borderCol, width: 0.5),
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
                        child: Icon(Icons.format_list_bulleted_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playback Queue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playlist.items.length} videos scheduled for playback',
                          style: TextStyle(fontSize: 12, color: textSecondary),
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
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                        label: const Text('Play from Top'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          final items = [...playlist.items]..shuffle();
                          notifier.setList(items, initialIndex: 0);
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: const Text('Shuffle'),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => notifier.setList([]),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Clear Queue'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textTertiary,
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => AddFromLibraryModal.show(context, ref),
                      icon: const Icon(Icons.video_library_rounded, size: 15, color: AppTheme.accent),
                      label: const Text('Add from Library'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                        side: BorderSide(
                          color: (isDark ? AppTheme.accent : const Color(0xFF0284C7)).withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addVideos(ref),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Files'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderCol),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => ManageFoldersModal.show(context),
                      icon: const Icon(Icons.folder_open_rounded, size: 15),
                      label: const Text('Manage Folders'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderCol),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addFolder(ref),
                      icon: const Icon(Icons.create_new_folder_rounded, size: 15),
                      label: const Text('Add Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF04131F),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
                              color: cardBg,
                              border: Border.all(color: borderCol),
                            ),
                            child: Center(
                              child: Icon(Icons.format_list_bulleted_rounded,
                                  size: 32, color: textSecondary),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Queue is Empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add videos from your app library, local files, or folders to queue them for continuous playback.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: textSecondary),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => AddFromLibraryModal.show(context, ref),
                                icon: const Icon(Icons.video_library_rounded, size: 16),
                                label: const Text('Add from Library'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: const Color(0xFF04131F),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _addVideos(ref),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Videos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderCol),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _addFolder(ref),
                                icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                                label: const Text('Add Folder'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderCol),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              ? AppTheme.accent.withValues(alpha: isDark ? 0.15 : 0.20)
                              : cardBg,
                          borderColor: isCurrent
                              ? AppTheme.accent.withValues(alpha: 0.6)
                              : borderCol,
                          blur: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () => notifier.playIndex(index),
                          child: Row(
                            children: [
                              // Index or Playing indicator
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppTheme.accent
                                      : (isDark ? const Color(0xFF1E2232) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: isCurrent
                                      ? const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFF04131F))
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isCurrent ? (isDark ? AppTheme.accent : const Color(0xFF0284C7)) : textPrimary,
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textSecondary,
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
                                  isCurrent ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: isCurrent ? (isDark ? AppTheme.accent : const Color(0xFF0284C7)) : textSecondary,
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
                                icon: Icon(Icons.delete_outline_rounded, size: 16, color: textSecondary),
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
