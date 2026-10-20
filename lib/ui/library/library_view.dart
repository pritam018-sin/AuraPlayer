import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';
import '../modals/open_network_modal.dart';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFolder;
  List<File> _scannedFiles = [];
  bool _isLoading = false;
  bool _isDraggingOver = false;

  final List<String> _videoExtensions = [
    '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v'
  ];

  @override
  void initState() {
    super.initState();
    _scanAllImportedFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanAllImportedFolders() async {
    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    final folders = storage.getImportedFolders();

    final files = <File>[];
    for (final folderPath in folders) {
      final dir = Directory(folderPath);
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              if (_videoExtensions.any((ext) => lower.endsWith(ext))) {
                files.add(entity);
              }
            }
          }
        } catch (_) {}
      }
    }

    setState(() {
      _scannedFiles = files;
      _isLoading = false;
    });
  }

  Future<void> _importFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await ref.read(storageServiceProvider).addImportedFolder(path);
      await _scanAllImportedFolders();
    }
  }

  Future<void> _importFiles() async {
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

  void _playAll({bool shuffle = false}) {
    var files = [..._filteredFiles];
    if (shuffle) files.shuffle();
    if (files.isNotEmpty) {
      final items = files.map((f) => PlaylistItem(
            path: f.path,
            title: f.path.split(RegExp(r'[/\\]')).last,
          )).toList();
      ref.read(playlistProvider.notifier).setList(items, initialIndex: 0);
    }
  }

  List<File> get _filteredFiles {
    var list = _scannedFiles;
    if (_selectedFolder != null) {
      list = list.where((f) => f.path.startsWith(_selectedFolder!)).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((f) => f.path.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final importedFolders = storage.getImportedFolders();
    final filtered = _filteredFiles;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingOver = true),
      onDragExited: (_) => setState(() => _isDraggingOver = false),
      onDragDone: (details) async {
        setState(() => _isDraggingOver = false);
        for (final file in details.files) {
          final isDir = FileSystemEntity.isDirectorySync(file.path);
          if (isDir) {
            await storage.addImportedFolder(file.path);
          } else {
            final lower = file.path.toLowerCase();
            if (_videoExtensions.any((ext) => lower.endsWith(ext))) {
              ref.read(playlistProvider.notifier).addItem(
                    PlaylistItem(path: file.path, title: file.name),
                    playImmediately: true,
                  );
              return;
            }
          }
        }
        await _scanAllImportedFolders();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: _isDraggingOver
              ? Border.all(color: AppTheme.accent, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Top Toolbar: Search & Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.6),
                border: const Border(
                  bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTheme.bodySmall,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search videos in library...',
                          hintStyle: AppTheme.caption.copyWith(color: AppTheme.textTertiary),
                          prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: AppTheme.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 14, color: AppTheme.textTertiary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Import Folder Button
                  ElevatedButton.icon(
                    onPressed: _importFolder,
                    icon: const Icon(CupertinoIcons.folder_badge_plus, size: 16),
                    label: const Text('Import Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Import Files Button
                  OutlinedButton.icon(
                    onPressed: _importFiles,
                    icon: const Icon(CupertinoIcons.plus, size: 16),
                    label: const Text('Add Files'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Open Stream Button
                  IconButton(
                    tooltip: 'Open Network Stream (URL)',
                    onPressed: () => OpenNetworkModal.show(context),
                    icon: const Icon(CupertinoIcons.globe, size: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            // Folder Filter Chips
            if (importedFolders.isNotEmpty)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _folderChip(
                      label: 'All Videos (${_scannedFiles.length})',
                      isSelected: _selectedFolder == null,
                      onTap: () => setState(() => _selectedFolder = null),
                    ),
                    ...importedFolders.map((folder) {
                      final name = folder.split(RegExp(r'[/\\]')).last;
                      final count = _scannedFiles.where((f) => f.path.startsWith(folder)).length;
                      return _folderChip(
                        label: '$name ($count)',
                        isSelected: _selectedFolder == folder,
                        onTap: () => setState(() => _selectedFolder = folder),
                        onDelete: () async {
                          await storage.removeImportedFolder(folder);
                          if (_selectedFolder == folder) _selectedFolder = null;
                          await _scanAllImportedFolders();
                        },
                      );
                    }),
                  ],
                ),
              ),

            // Video Grid / Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : filtered.isEmpty
                      ? _emptyLibraryView()
                      : Column(
                          children: [
                            // Action stats bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${filtered.length} videos found',
                                    style: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _playAll(shuffle: false),
                                        icon: const Icon(CupertinoIcons.play_circle, size: 16),
                                        label: const Text('Play All'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.accent,
                                          textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _playAll(shuffle: true),
                                        icon: const Icon(CupertinoIcons.shuffle, size: 16),
                                        label: const Text('Shuffle'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.textSecondary,
                                          textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Video Cards Grid
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 260,
                                  mainAxisExtent: 210,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final file = filtered[index];
                                  return _videoCard(file);
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _folderChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.glassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    CupertinoIcons.clear,
                    size: 11,
                    color: isSelected ? Colors.white70 : AppTheme.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoCard(File file) {
    final storage = ref.read(storageServiceProvider);
    final title = file.path.split(RegExp(r'[/\\]')).last;
    final ext = title.split('.').last.toUpperCase();
    final savedPos = storage.getPosition(file.path);

    int sizeBytes = 0;
    try {
      sizeBytes = file.lengthSync();
    } catch (_) {}

    return FrostedGlass(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      fillColor: AppTheme.surfaceSecondary.withValues(alpha: 0.65),
      onTap: () {
        ref.read(playlistProvider.notifier).addItem(
              PlaylistItem(path: file.path, title: title),
              playImmediately: true,
            );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Preview Box with Format Badge
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceTertiary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.play_fill, size: 20, color: AppTheme.accent),
                      ),
                    ),
                  ),
                  // Format Badge (e.g. MKV, MP4)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Text(
                        ext,
                        style: AppTheme.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  // File Size Badge
                  if (sizeBytes > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatFileSize(sizeBytes),
                          style: AppTheme.caption.copyWith(fontSize: 10, color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  savedPos.inSeconds > 5
                      ? 'Resume at ${_formatDuration(savedPos)}'
                      : 'Unwatched',
                  style: AppTheme.caption.copyWith(
                    color: savedPos.inSeconds > 5 ? AppTheme.accent : AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLibraryView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.auraGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(CupertinoIcons.folder_badge_plus, size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text('Build Your Video Library', style: AppTheme.headline),
            const SizedBox(height: 8),
            Text(
              'Import your Movies, Shows, or Videos folder to browse your collection with instant playback.',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _importFolder,
              icon: const Icon(CupertinoIcons.folder_fill, size: 18),
              label: const Text('Import Video Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
