import 'dart:io';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../services/thumbnail_service.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';
import '../modals/manage_folders_modal.dart';

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

  String _sortMode = 'recent'; // 'recent', 'name_asc', 'name_desc', 'size_desc'
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    ThumbnailService.updateNotifier.addListener(_onThumbnailsUpdated);
    _scanAllImportedFolders();
  }

  void _onThumbnailsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThumbnailService.updateNotifier.removeListener(_onThumbnailsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _safeScanDir(Directory dir, List<File> target, {int depth = 0}) {
    if (depth > 5) return;
    try {
      final entities = dir.listSync(recursive: false, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (_videoExtensions.any((ext) => lower.endsWith(ext))) {
            target.add(entity);
          }
        } else if (entity is Directory) {
          final name = entity.path.split(RegExp(r'[/\\]')).last;
          if (!name.startsWith('.') && !name.startsWith(r'$') && name != 'node_modules') {
            _safeScanDir(entity, target, depth: depth + 1);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _scanAllImportedFolders() async {
    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    final folders = storage.getImportedFolders();

    final files = <File>[];
    for (final folderPath in folders) {
      final dir = Directory(folderPath);
      if (dir.existsSync()) {
        _safeScanDir(dir, files);
      }
    }

    setState(() {
      _scannedFiles = files;
      _isLoading = false;
    });

    if (files.isNotEmpty) {
      ThumbnailService.batchGenerateThumbnails(files.map((f) => f.path).toList());
    }
  }

  Future<void> _importFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await ref.read(storageServiceProvider).addImportedFolder(path);
      await _scanAllImportedFolders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added folder to library: ${path.split(RegExp(r'[/\\]')).last}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
      allowMultiple: true,
    );

    if (result != null && result.paths.isNotEmpty) {
      final storage = ref.read(storageServiceProvider);
      final validPaths = result.paths.whereType<String>().toList();
      for (final p in validPaths) {
        final parentDir = File(p).parent.path;
        await storage.addImportedFolder(parentDir);
      }
      await _scanAllImportedFolders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${validPaths.length} video(s) to library'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    var list = [..._scannedFiles];
    if (_selectedFolder != null) {
      list = list.where((f) => f.path.startsWith(_selectedFolder!)).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((f) => f.path.toLowerCase().contains(q)).toList();
    }

    switch (_sortMode) {
      case 'name_asc':
        list.sort((a, b) => a.path.split(RegExp(r'[/\\]')).last.toLowerCase().compareTo(b.path.split(RegExp(r'[/\\]')).last.toLowerCase()));
        break;
      case 'name_desc':
        list.sort((a, b) => b.path.split(RegExp(r'[/\\]')).last.toLowerCase().compareTo(a.path.split(RegExp(r'[/\\]')).last.toLowerCase()));
        break;
      case 'size_desc':
        list.sort((a, b) {
          int sa = 0, sb = 0;
          try { sa = a.lengthSync(); } catch (_) {}
          try { sb = b.lengthSync(); } catch (_) {}
          return sb.compareTo(sa);
        });
        break;
      case 'recent':
      default:
        list.sort((a, b) {
          DateTime da = DateTime.fromMillisecondsSinceEpoch(0);
          DateTime db = DateTime.fromMillisecondsSinceEpoch(0);
          try { da = a.lastModifiedSync(); } catch (_) {}
          try { db = b.lastModifiedSync(); } catch (_) {}
          return db.compareTo(da);
        });
        break;
    }

    return list;
  }

  File? _getHeroFeaturedFile(List<File> files) {
    if (files.isEmpty) return null;
    final storage = ref.read(storageServiceProvider);
    final recents = storage.getRecentFiles();
    for (final recent in recents) {
      for (final f in files) {
        if (f.path == recent.path) {
          return f;
        }
      }
    }
    return files.first;
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  int _calculateTotalSize(List<File> files) {
    int total = 0;
    for (final f in files) {
      try {
        total += f.lengthSync();
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final importedFolders = storage.getImportedFolders();
    final filtered = _filteredFiles;
    final totalBytes = _calculateTotalSize(filtered);
    final heroFeatured = _getHeroFeaturedFile(filtered);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;

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
          color: Colors.transparent,
          border: _isDraggingOver
              ? Border.all(color: AppTheme.accent, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Single Unified Cinema Search & Filter Strip with Frosted Glass Blur
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surface.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.38),
                    border: Border(
                      bottom: BorderSide(color: borderCol, width: 0.5),
                    ),
                  ),
                  child: Row(
                children: [
                  // 1. Search Field
                  Container(
                    width: 250,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceSecondary : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderCol),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search ${_scannedFiles.length} videos...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, size: 16, color: textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, size: 15, color: textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 2. Folder Filter Chips (Horizontal List)
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _folderChip(
                            label: 'All Media (${_scannedFiles.length})',
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
                  ),

                  const SizedBox(width: 14),

                  // 3. Quick Actions: Add Folder, Manage Folders, Remove Folder & Add Files
                  if (_selectedFolder != null) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final folderToRemove = _selectedFolder!;
                        await storage.removeImportedFolder(folderToRemove);
                        setState(() => _selectedFolder = null);
                        await _scanAllImportedFolders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed folder from library: ${folderToRemove.split(RegExp(r'[/\\]')).last}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFF43F5E)),
                      label: const Text('Remove Folder', style: TextStyle(color: Color(0xFFF43F5E))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF43F5E),
                        side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => ManageFoldersModal.show(context, onFoldersChanged: _scanAllImportedFolders),
                    icon: Icon(Icons.folder_shared_rounded, size: 15, color: textPrimary),
                    label: Text('Manage Folders', style: TextStyle(color: textPrimary)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _importFolder,
                    icon: Icon(Icons.create_new_folder_rounded, size: 15, color: textPrimary),
                    label: Text('Add Folder', style: TextStyle(color: textPrimary)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _importFiles,
                    icon: Icon(Icons.add_rounded, size: 16, color: textPrimary),
                    label: Text('Add Files', style: TextStyle(color: textPrimary)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : filtered.isEmpty
                      ? _emptyLibraryView()
                      : CustomScrollView(
                          slivers: [
                            // 1. Apple TV / Infuse 8 Cinematic Hero Spotlight
                            if (_searchController.text.isEmpty && heroFeatured != null)
                              SliverToBoxAdapter(
                                child: _buildHeroSpotlight(heroFeatured),
                              ),

                            // 2. Stats & Quick Actions Toolbar
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${filtered.length} TITLES',
                                          style: AppTheme.caption.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•  ${_formatFileSize(totalBytes)} TOTAL',
                                          style: AppTheme.caption.copyWith(
                                            color: textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // Sort Dropdown Menu
                                        PopupMenuButton<String>(
                                          tooltip: 'Sort By',
                                          color: isDark ? AppTheme.surface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: borderCol),
                                          ),
                                          onSelected: (val) => setState(() => _sortMode = val),
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'recent',
                                              height: 32,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.access_time_rounded, size: 15, color: _sortMode == 'recent' ? AppTheme.accent : textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text('Recently Added', style: TextStyle(fontSize: 12.5, color: _sortMode == 'recent' ? AppTheme.accent : textPrimary)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'name_asc',
                                              height: 32,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.sort_by_alpha_rounded, size: 15, color: _sortMode == 'name_asc' ? AppTheme.accent : textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text('Name (A to Z)', style: TextStyle(fontSize: 12.5, color: _sortMode == 'name_asc' ? AppTheme.accent : textPrimary)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'name_desc',
                                              height: 32,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.sort_by_alpha_rounded, size: 15, color: _sortMode == 'name_desc' ? AppTheme.accent : textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text('Name (Z to A)', style: TextStyle(fontSize: 12.5, color: _sortMode == 'name_desc' ? AppTheme.accent : textPrimary)),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'size_desc',
                                              height: 32,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.data_usage_rounded, size: 15, color: _sortMode == 'size_desc' ? AppTheme.accent : textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text('File Size (Largest)', style: TextStyle(fontSize: 12.5, color: _sortMode == 'size_desc' ? AppTheme.accent : textPrimary)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppTheme.surfaceSecondary : Colors.white.withValues(alpha: 0.85),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: borderCol),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.swap_vert_rounded, size: 15, color: AppTheme.accent),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _sortMode == 'recent'
                                                      ? 'Recent'
                                                      : _sortMode == 'name_asc'
                                                          ? 'Name A-Z'
                                                          : _sortMode == 'name_desc'
                                                              ? 'Name Z-A'
                                                              : 'Size',
                                                  style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textSecondary),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Grid / List View Toggle
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? AppTheme.surfaceSecondary : Colors.white.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderCol),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => setState(() => _isGridView = true),
                                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                                child: Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: _isGridView ? AppTheme.accent.withValues(alpha: 0.25) : Colors.transparent,
                                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                                  ),
                                                  child: Icon(
                                                    Icons.grid_view_rounded,
                                                    size: 15,
                                                    color: _isGridView ? AppTheme.accent : textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Container(width: 1, height: 16, color: borderCol),
                                              InkWell(
                                                onTap: () => setState(() => _isGridView = false),
                                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                                child: Container(
                                                  padding: const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: !_isGridView ? AppTheme.accent.withValues(alpha: 0.25) : Colors.transparent,
                                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                                  ),
                                                  child: Icon(
                                                    Icons.view_list_rounded,
                                                    size: 16,
                                                    color: !_isGridView ? AppTheme.accent : textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        ElevatedButton.icon(
                                          onPressed: () => _playAll(shuffle: false),
                                          icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                                          label: const Text('Play All'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                                            foregroundColor: AppTheme.accent,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: const BorderSide(color: AppTheme.accent, width: 0.8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          onPressed: () => _playAll(shuffle: true),
                                          icon: Icon(Icons.shuffle_rounded, size: 15, color: textSecondary),
                                          label: Text('Shuffle', style: TextStyle(color: textSecondary)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: textSecondary,
                                            side: BorderSide(color: borderCol),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. Media Presentation (16:9 Grid or Pro Compact List)
                            if (_isGridView)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 310,
                                    mainAxisExtent: 235,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final file = filtered[index];
                                      return _videoCard(file);
                                    },
                                    childCount: filtered.length,
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final file = filtered[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _videoListTile(file),
                                      );
                                    },
                                    childCount: filtered.length,
                                  ),
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

  Widget _buildHeroSpotlight(File file) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;

    final rawName = file.path.split(RegExp(r'[/\\]')).last;
    final cleanTitle = rawName.contains('.')
        ? rawName.substring(0, rawName.lastIndexOf('.'))
        : rawName;
    final ext = rawName.contains('.') ? rawName.split('.').last.toUpperCase() : 'VIDEO';
    final storage = ref.read(storageServiceProvider);
    final savedPos = storage.getPosition(file.path);
    final thumb = ThumbnailService.getCachedThumbnail(file.path);
    int sizeBytes = 0;
    try {
      sizeBytes = file.lengthSync();
    } catch (_) {}

    final scrimColor = isDark ? const Color(0xFF0D0D12) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 14, 28, 6),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (thumbnail cover with gradient scrim)
            if (thumb != null)
              Positioned.fill(
                child: Image.file(
                  thumb,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, _, _) => _fallbackThumb(),
                ),
              )
            else
              Positioned.fill(child: _fallbackThumb()),

            // Cinematic multi-directional gradient scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scrimColor,
                      scrimColor.withValues(alpha: 0.95),
                      scrimColor.withValues(alpha: 0.75),
                      scrimColor.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 0.65, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // Content Left Overlay
            Positioned(
              top: 22,
              bottom: 22,
              left: 28,
              right: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE11D48), Color(0xFFFA2D48)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              savedPos.inSeconds > 5 ? 'CONTINUE WATCHING' : 'FEATURED MEDIA',
                              style: AppTheme.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderCol, width: 0.8),
                        ),
                        child: Text(
                          ext,
                          style: AppTheme.caption.copyWith(
                            color: textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (sizeBytes > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatFileSize(sizeBytes),
                          style: AppTheme.caption.copyWith(
                            color: textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hero Title
                  Text(
                    cleanTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.headline.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle / Status
                  Text(
                    savedPos.inSeconds > 5
                        ? 'Paused at ${_formatDuration(savedPos)} • Click resume to continue playback where you left off'
                        : 'Ready to play in ultra-smooth high definition with full hardware acceleration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption.copyWith(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(playlistProvider.notifier).addItem(
                                PlaylistItem(path: file.path, title: cleanTitle),
                                playImmediately: true,
                              );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text(savedPos.inSeconds > 5 ? 'Resume Watching' : 'Play Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: const Color(0xFF04131F),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          shadowColor: AppTheme.accent.withValues(alpha: 0.5),
                          textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (savedPos.inSeconds > 5) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            storage.setPosition(file.path, Duration.zero);
                            ref.read(playlistProvider.notifier).addItem(
                                  PlaylistItem(path: file.path, title: cleanTitle),
                                  playImmediately: true,
                                );
                          },
                          icon: Icon(Icons.replay_rounded, size: 15, color: textPrimary),
                          label: Text('From Beginning', style: TextStyle(color: textPrimary)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderCol),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      alignment: Alignment.center,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.auraGradient : null,
            color: isSelected ? null : (isDark ? AppTheme.surfaceSecondary : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : borderCol,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: isSelected ? const Color(0xFF04131F) : textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 14,
                    color: isSelected ? const Color(0xFF04131F).withValues(alpha: 0.7) : textSecondary,
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0F1420).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.30);

    final storage = ref.read(storageServiceProvider);
    final rawName = file.path.split(RegExp(r'[/\\]')).last;
    final ext = rawName.contains('.') ? rawName.split('.').last.toUpperCase() : 'VIDEO';
    final savedPos = storage.getPosition(file.path);

    // Clean display title without raw extension
    final cleanTitle = rawName.contains('.')
        ? rawName.substring(0, rawName.lastIndexOf('.'))
        : rawName;

    int sizeBytes = 0;
    try {
      sizeBytes = file.lengthSync();
    } catch (_) {}

    final thumb = ThumbnailService.getCachedThumbnail(file.path);
    if (thumb == null) {
      ThumbnailService.generateThumbnail(file.path);
    }

    return FrostedGlass(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      blur: 35,
      fillColor: cardBg,
      borderColor: borderCol,
      onTap: () {
        ref.read(playlistProvider.notifier).addItem(
              PlaylistItem(path: file.path, title: cleanTitle),
              playImmediately: true,
            );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Cinematic Thumbnail Box
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Actual Thumbnail or High-End Cinema Fallback
                  if (thumb != null) ...[
                    Image.file(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackThumb(),
                    ),
                    // Cinematic dark bottom gradient vignette
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ] else ...[
                    _fallbackThumb(),
                  ],

                  // Top Badges Row (Format + Quality + 3-Dots Menu)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Format Badge (e.g. MKV, MP4)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: borderCol),
                              ),
                              child: Text(
                                ext,
                                style: AppTheme.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Resolution Badge
                            if (cleanTitle.toLowerCase().contains('4k') || cleanTitle.toLowerCase().contains('2160p'))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAB308).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '4K HDR',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            else if (cleanTitle.toLowerCase().contains('1080p') || cleanTitle.toLowerCase().contains('fhd'))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '1080P',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // 3-Dots Quick Actions Menu
                        PopupMenuButton<String>(
                          tooltip: 'Options',
                          color: isDark ? AppTheme.surface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderCol),
                          ),
                          onSelected: (val) async {
                            if (val == 'play') {
                              ref.read(playlistProvider.notifier).addItem(
                                    PlaylistItem(path: file.path, title: cleanTitle),
                                    playImmediately: true,
                                  );
                            } else if (val == 'restart') {
                              storage.setPosition(file.path, Duration.zero);
                              ref.read(playlistProvider.notifier).addItem(
                                    PlaylistItem(path: file.path, title: cleanTitle),
                                    playImmediately: true,
                                  );
                            } else if (val == 'queue') {
                              ref.read(playlistProvider.notifier).addItem(
                                    PlaylistItem(path: file.path, title: cleanTitle),
                                    playImmediately: false,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to playlist: $cleanTitle'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (val == 'explorer') {
                              Process.run('explorer.exe', ['/select,', file.path]);
                            } else if (val == 'copy') {
                              final sm = ScaffoldMessenger.of(context);
                              await Clipboard.setData(ClipboardData(text: file.path));
                              sm.showSnackBar(
                                const SnackBar(
                                  content: Text('File path copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'play',
                              height: 32,
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow_rounded, size: 16, color: AppTheme.accent),
                                  const SizedBox(width: 8),
                                  Text('Play Now', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                                ],
                              ),
                            ),
                            if (savedPos.inSeconds > 5)
                              PopupMenuItem(
                                value: 'restart',
                                height: 32,
                                child: Row(
                                  children: [
                                    Icon(Icons.replay_rounded, size: 15, color: textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Play from Start', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'queue',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(Icons.playlist_add_rounded, size: 16, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Text('Add to Queue', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem(
                              value: 'explorer',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(Icons.folder_open_rounded, size: 15, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Text('Show in Explorer', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copy',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(Icons.content_copy_rounded, size: 15, color: textSecondary),
                                  const SizedBox(width: 8),
                                  Text('Copy Path', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Icon(Icons.more_vert, size: 20, color: textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Play Button Overlay
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, size: 24, color: Colors.white),
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
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatFileSize(sizeBytes),
                          style: AppTheme.caption.copyWith(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                  // Resume Watch Progress Line
                  if (savedPos.inSeconds > 5)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3.5,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.45,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              boxShadow: [
                                BoxShadow(color: AppTheme.accent, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Metadata Details Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: rawName,
                  child: Text(
                    cleanTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.2,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      savedPos.inSeconds > 5
                          ? 'Resume at ${_formatDuration(savedPos)}'
                          : 'Unwatched',
                      style: AppTheme.caption.copyWith(
                        color: savedPos.inSeconds > 5 ? AppTheme.accent : textSecondary,
                        fontSize: 11,
                        fontWeight: savedPos.inSeconds > 5 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      ext,
                      style: AppTheme.caption.copyWith(
                        color: textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoListTile(File file) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0F1420).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.30);

    final storage = ref.read(storageServiceProvider);
    final rawName = file.path.split(RegExp(r'[/\\]')).last;
    final ext = rawName.contains('.') ? rawName.split('.').last.toUpperCase() : 'VIDEO';
    final savedPos = storage.getPosition(file.path);

    final cleanTitle = rawName.contains('.')
        ? rawName.substring(0, rawName.lastIndexOf('.'))
        : rawName;

    int sizeBytes = 0;
    try {
      sizeBytes = file.lengthSync();
    } catch (_) {}

    final thumb = ThumbnailService.getCachedThumbnail(file.path);
    if (thumb == null) {
      ThumbnailService.generateThumbnail(file.path);
    }

    final parentDir = file.parent.path.split(RegExp(r'[/\\]')).last;

    return FrostedGlass(
      borderRadius: 12,
      blur: 35,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      fillColor: cardBg,
      borderColor: borderCol,
      onTap: () {
        ref.read(playlistProvider.notifier).addItem(
              PlaylistItem(path: file.path, title: cleanTitle),
              playImmediately: true,
            );
      },
      child: Row(
        children: [
          // 1. Mini 16:9 Thumbnail (width 80, height 48)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141620) : const Color(0xFFE2E8F0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb != null)
                    Image.file(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackThumb(),
                    )
                  else
                    _fallbackThumb(),
                  // Play Icon Overlay
                  Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // 2. Format Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderCol),
            ),
            child: Text(
              ext,
              style: AppTheme.caption.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
                letterSpacing: 0.4,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 3. Title & Path Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: rawName,
                  child: Text(
                    cleanTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 12, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      parentDir,
                      style: AppTheme.caption.copyWith(color: textSecondary, fontSize: 11),
                    ),
                    if (savedPos.inSeconds > 5) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Text(
                          'Resume ${_formatDuration(savedPos)}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 4. File Size
          Text(
            _formatFileSize(sizeBytes),
            style: AppTheme.caption.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 14),

          // 5. 3-Dots Menu
          PopupMenuButton<String>(
            tooltip: 'Options',
            color: isDark ? AppTheme.surface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderCol),
            ),
            onSelected: (val) async {
              if (val == 'play') {
                ref.read(playlistProvider.notifier).addItem(
                      PlaylistItem(path: file.path, title: cleanTitle),
                      playImmediately: true,
                    );
              } else if (val == 'restart') {
                storage.setPosition(file.path, Duration.zero);
                ref.read(playlistProvider.notifier).addItem(
                      PlaylistItem(path: file.path, title: cleanTitle),
                      playImmediately: true,
                    );
              } else if (val == 'queue') {
                ref.read(playlistProvider.notifier).addItem(
                      PlaylistItem(path: file.path, title: cleanTitle),
                      playImmediately: false,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to playlist: $cleanTitle'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (val == 'explorer') {
                Process.run('explorer.exe', ['/select,', file.path]);
              } else if (val == 'copy') {
                final sm = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: file.path));
                sm.showSnackBar(
                  const SnackBar(
                    content: Text('File path copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'play',
                height: 32,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 16, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Text('Play Now', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                  ],
                ),
              ),
              if (savedPos.inSeconds > 5)
                PopupMenuItem(
                  value: 'restart',
                  height: 32,
                  child: Row(
                    children: [
                      Icon(Icons.replay_rounded, size: 15, color: textSecondary),
                      const SizedBox(width: 8),
                      Text('Play from Start', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'queue',
                height: 32,
                child: Row(
                  children: [
                    Icon(Icons.playlist_add_rounded, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Text('Add to Queue', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'explorer',
                height: 32,
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 15, color: textSecondary),
                    const SizedBox(width: 8),
                    Text('Show in Explorer', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                height: 32,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_rounded, size: 15, color: textSecondary),
                    const SizedBox(width: 8),
                    Text('Copy Path', style: TextStyle(fontSize: 12.5, color: textPrimary)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(Icons.more_vert, size: 20, color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141620), Color(0xFF090A0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AURA CINEMA',
              style: AppTheme.caption.copyWith(
                fontSize: 9.5,
                letterSpacing: 1.4,
                color: Colors.white38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyLibraryView() {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0F1420).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.35);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: FrostedGlass(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          blur: 36,
          fillColor: cardBg,
          borderColor: borderCol,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                      color: AppTheme.accent.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.movie_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Build Your Cinema Library',
                style: AppTheme.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Import your local Movies, Series, or Videos folders to browse your collection with instant 4K HDR playback and auto-generated high-resolution thumbnails.',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(color: textSecondary, height: 1.45),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _importFolder,
                    icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                    label: const Text('Import Video Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF04131F),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importFiles,
                    icon: Icon(Icons.add_rounded, size: 16, color: textPrimary),
                    label: Text('Add Media Files', style: TextStyle(color: textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Drag & drop video files or folders anywhere onto this window',
                      style: AppTheme.caption.copyWith(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
