import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../services/thumbnail_service.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

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

    if (files.isNotEmpty) {
      ThumbnailService.batchGenerateThumbnails(files.map((f) => f.path).toList());
    }
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
            // Single Unified Cinema Search & Filter Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                border: const Border(
                  bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // 1. Search Field
                  Container(
                    width: 250,
                    height: 36,
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
                        hintText: 'Search ${_scannedFiles.length} videos...',
                        hintStyle: AppTheme.caption.copyWith(color: AppTheme.textTertiary),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 15, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 13, color: AppTheme.textTertiary),
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
                      height: 36,
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

                  // 3. Quick Actions: Add Folder & Add Files
                  OutlinedButton.icon(
                    onPressed: _importFolder,
                    icon: const Icon(CupertinoIcons.folder_badge_plus, size: 14),
                    label: const Text('Add Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _importFiles,
                    icon: const Icon(CupertinoIcons.plus, size: 14),
                    label: const Text('Add Files'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•  ${_formatFileSize(totalBytes)} TOTAL',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.textTertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _playAll(shuffle: false),
                                          icon: const Icon(CupertinoIcons.play_circle_fill, size: 16),
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
                                          icon: const Icon(CupertinoIcons.shuffle, size: 15),
                                          label: const Text('Shuffle'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.textSecondary,
                                            side: const BorderSide(color: AppTheme.glassBorder),
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

                            // 3. 16:9 Cinematic Video Cards Grid
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

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 14, 28, 6),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
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

            // Cinematic multi-directional dark gradient scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0D0D12),
                      const Color(0xFF0D0D12).withValues(alpha: 0.95),
                      const Color(0xFF0D0D12).withValues(alpha: 0.75),
                      const Color(0xFF0D0D12).withValues(alpha: 0.25),
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
                            const Icon(CupertinoIcons.sparkles, size: 10, color: Colors.white),
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
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                        ),
                        child: Text(
                          ext,
                          style: AppTheme.caption.copyWith(
                            color: Colors.white70,
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
                            color: AppTheme.textTertiary,
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
                      color: AppTheme.textSecondary,
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
                        icon: const Icon(CupertinoIcons.play_fill, size: 14),
                        label: Text(savedPos.inSeconds > 5 ? 'Resume Watching' : 'Play Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
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
                          icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 13),
                          label: const Text('From Beginning'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.glassBorder),
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
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 7, bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.auraGradient : null,
            color: isSelected ? null : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.glassBorder,
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
                  color: isSelected ? const Color(0xFF04131F) : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    CupertinoIcons.clear_circled,
                    size: 13,
                    color: isSelected ? const Color(0xFF04131F).withValues(alpha: 0.7) : AppTheme.textTertiary,
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
      fillColor: const Color(0xFF111118).withValues(alpha: 0.8),
      borderColor: AppTheme.glassBorder,
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
                                border: Border.all(color: AppTheme.glassBorder),
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
                          color: AppTheme.surface.withValues(alpha: 0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.glassBorder),
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
                            const PopupMenuItem(
                              value: 'play',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.play_fill, size: 14, color: AppTheme.accent),
                                  SizedBox(width: 8),
                                  Text('Play Now', style: TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                            if (savedPos.inSeconds > 5)
                              const PopupMenuItem(
                                value: 'restart',
                                height: 32,
                                child: Row(
                                  children: [
                                    Icon(CupertinoIcons.arrow_counterclockwise, size: 14, color: Colors.white70),
                                    SizedBox(width: 8),
                                    Text('Play from Start', style: TextStyle(fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'queue',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.plus_circle, size: 14, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Add to Queue', style: TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            const PopupMenuItem(
                              value: 'explorer',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.folder, size: 14, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Show in Explorer', style: TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Copy Path', style: TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.ellipsis, size: 13, color: Colors.white),
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
                        child: Icon(CupertinoIcons.play_fill, size: 19, color: Colors.white),
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
                        color: savedPos.inSeconds > 5 ? AppTheme.accent : AppTheme.textTertiary,
                        fontSize: 11,
                        fontWeight: savedPos.inSeconds > 5 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      ext,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textTertiary,
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

  Widget _fallbackThumb() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1E28), Color(0xFF12121A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.film,
              size: 32,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 6),
            Text(
              'AURA CINEMA',
              style: AppTheme.caption.copyWith(
                fontSize: 9,
                letterSpacing: 1.2,
                color: Colors.white24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyLibraryView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                  child: Icon(CupertinoIcons.film_fill, size: 36, color: Color(0xFF04131F)),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Build Your Cinema Library',
                style: AppTheme.headline.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Import your local Movies, Series, or Videos folders to browse your collection with instant 4K HDR playback and auto-generated high-resolution thumbnails.',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _importFolder,
                    icon: const Icon(CupertinoIcons.folder_badge_plus, size: 16),
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
                    icon: const Icon(CupertinoIcons.plus, size: 16, color: Colors.white),
                    label: const Text('Add Media Files', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.glassBorderHover),
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
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 13, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Drag & drop video files or folders anywhere onto this window',
                      style: AppTheme.caption.copyWith(color: AppTheme.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
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
