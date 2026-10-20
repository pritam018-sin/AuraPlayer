import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _isDraggingOver = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      final items = result.paths
          .whereType<String>()
          .map((p) => PlaylistItem(
                path: p,
                title: p.split(RegExp(r'[/\\]')).last,
              ))
          .toList();

      if (items.isNotEmpty) {
        ref.read(playlistProvider.notifier).setList(items, initialIndex: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final recents = storage.getRecentFiles();

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingOver = true),
      onDragExited: (_) => setState(() => _isDraggingOver = false),
      onDragDone: (details) {
        setState(() => _isDraggingOver = false);
        final paths = details.files.map((f) => f.path).toList();
        final videoExtensions = ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v'];
        final validPaths = paths.where((p) {
          final lower = p.toLowerCase();
          return videoExtensions.any((ext) => lower.endsWith(ext));
        }).toList();

        if (validPaths.isNotEmpty) {
          final items = validPaths
              .map((p) => PlaylistItem(path: p, title: p.split(RegExp(r'[/\\]')).last))
              .toList();
          ref.read(playlistProvider.notifier).setList(items, initialIndex: 0);
        }
      },
      child: Container(
        color: AppTheme.background,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drop Zone Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 640,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                  decoration: BoxDecoration(
                    color: _isDraggingOver
                        ? AppTheme.accent.withValues(alpha: 0.08)
                        : AppTheme.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isDraggingOver
                          ? AppTheme.accent
                          : AppTheme.glassBorder,
                      width: _isDraggingOver ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isDraggingOver ? 0.45 : 0.25),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isDraggingOver
                              ? AppTheme.accent.withValues(alpha: 0.2)
                              : AppTheme.surfaceSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isDraggingOver
                                ? AppTheme.accent.withValues(alpha: 0.5)
                                : AppTheme.glassBorder,
                          ),
                        ),
                        child: Icon(
                          _isDraggingOver
                              ? CupertinoIcons.arrow_down_doc_fill
                              : CupertinoIcons.play_circle_fill,
                          size: 38,
                          color: _isDraggingOver ? AppTheme.accent : AppTheme.accentHover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isDraggingOver ? 'Drop Video to Play' : 'Drag & Drop Video Files Here',
                        style: AppTheme.headline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supports MP4, MKV, AVI, WebM, MOV, and more',
                        style: AppTheme.caption,
                      ),
                      const SizedBox(height: 28),

                      // Open Button
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(CupertinoIcons.folder_badge_plus, size: 18),
                        label: const Text('Open Video File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Files Section
                if (recents.isNotEmpty) ...[
                  const SizedBox(height: 44),
                  SizedBox(
                    width: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Videos',
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await storage.clearRecentFiles();
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textTertiary,
                                textStyle: AppTheme.caption,
                              ),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recents.length > 5 ? 5 : recents.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = recents[index];
                            return _recentCard(item);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentCard(RecentItem item) {
    final progress = item.duration.inMilliseconds > 0
        ? (item.position.inMilliseconds / item.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return FrostedGlass(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: AppTheme.surface.withValues(alpha: 0.55),
      onTap: () {
        ref.read(playlistProvider.notifier).setList([
          PlaylistItem(path: item.path, title: item.title),
        ]);
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: const Icon(
              CupertinoIcons.film,
              size: 20,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Last watched ${DateFormat.yMMMd().format(item.lastPlayed)}',
                      style: AppTheme.caption,
                    ),
                    if (progress > 0.02) ...[
                      const SizedBox(width: 8),
                      Text('•', style: AppTheme.caption),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}% completed',
                        style: AppTheme.caption.copyWith(color: AppTheme.accent),
                      ),
                    ],
                  ],
                ),
                if (progress > 0.02) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2.5,
                      backgroundColor: AppTheme.surfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            CupertinoIcons.play_fill,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}
