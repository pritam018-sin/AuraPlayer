import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_models.dart';
import '../../services/thumbnail_service.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class AddFromLibraryModal extends ConsumerStatefulWidget {
  const AddFromLibraryModal({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: const AddFromLibraryModal(),
      ),
    );
  }

  @override
  ConsumerState<AddFromLibraryModal> createState() => _AddFromLibraryModalState();
}

class _AddFromLibraryModalState extends ConsumerState<AddFromLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  List<File> _libraryFiles = [];
  bool _isLoading = true;
  int _activeFilter = 0; // 0 = Library Folders, 1 = Recent Media, 2 = System Videos

  final List<String> _videoExts = [
    '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v'
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
          if (_videoExts.any((ext) => lower.endsWith(ext))) {
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

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    final folders = storage.getImportedFolders();
    final List<File> files = [];

    await Future.microtask(() {
      // 1. Scan user's imported folders
      for (final folderPath in folders) {
        final dir = Directory(folderPath);
        if (dir.existsSync()) {
          _safeScanDir(dir, files);
        }
      }

      // 2. Include recent files that exist on disk
      final recents = storage.getRecentFiles();
      for (final r in recents) {
        final f = File(r.path);
        if (f.existsSync() && !files.any((existing) => existing.path == f.path)) {
          files.add(f);
        }
      }

      // 3. Auto-discover common Windows video locations if library is small
      if (files.length < 5) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final commonDirs = [
            '$userProfile\\Videos',
            '$userProfile\\Downloads',
            '$userProfile\\Desktop',
          ];
          for (final dirPath in commonDirs) {
            try {
              final dir = Directory(dirPath);
              if (dir.existsSync()) {
                final list = dir
                    .listSync(recursive: false, followLinks: false)
                    .whereType<File>()
                    .where((f) => _videoExts.any((ext) => f.path.toLowerCase().endsWith(ext)));
                for (final vid in list) {
                  if (!files.any((existing) => existing.path == vid.path)) {
                    files.add(vid);
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    });

    if (mounted) {
      setState(() {
        _libraryFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _browseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv', 'ts', 'm4v'],
      allowMultiple: true,
    );
    if (result != null && result.paths.isNotEmpty) {
      for (final path in result.paths.whereType<String>()) {
        ref.read(playlistProvider.notifier).addItem(
              PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
              playImmediately: false,
            );
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result.paths.length} file(s) to queue'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await ref.read(storageServiceProvider).addImportedFolder(path);
      await _loadVideos();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final playlist = ref.watch(playlistProvider);
    final storage = ref.watch(storageServiceProvider);
    final query = _searchController.text.trim().toLowerCase();

    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.65);
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;

    final recentItems = storage.getRecentFiles();

    final List<PlaylistItem> candidates = [];
    final seenPaths = <String>{};

    void addCandidate(String path, String title) {
      if (seenPaths.contains(path)) return;
      seenPaths.add(path);
      if (query.isEmpty || title.toLowerCase().contains(query) || path.toLowerCase().contains(query)) {
        candidates.add(PlaylistItem(path: path, title: title));
      }
    }

    if (_activeFilter == 0) {
      // 0 = All Available Media (Discovered + Recent + Active Playlist)
      for (final f in _libraryFiles) {
        final name = f.path.split(RegExp(r'[/\\]')).last;
        final cleanTitle = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
        addCandidate(f.path, cleanTitle);
      }
      for (final r in recentItems) {
        addCandidate(r.path, r.title);
      }
      for (final p in playlist.items) {
        addCandidate(p.path, p.title);
      }
    } else if (_activeFilter == 1) {
      // 1 = Library Folders
      for (final f in _libraryFiles) {
        final name = f.path.split(RegExp(r'[/\\]')).last;
        final cleanTitle = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
        addCandidate(f.path, cleanTitle);
      }
    } else {
      // 2 = Recent Media
      for (final r in recentItems) {
        addCandidate(r.path, r.title);
      }
    }

    final queuedPaths = playlist.items.map((i) => i.path).toSet();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          fillColor: isDark
              ? const Color(0xFF0C101A).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.65),
          borderColor: borderCol,
          blur: 35,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
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
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.video_library_rounded, size: 19, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add In-App Videos to Queue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Select from discovered library folders or recently played media',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quick Browse files button
                        OutlinedButton.icon(
                          onPressed: _browseFiles,
                          icon: const Icon(Icons.file_open_rounded, size: 13),
                          label: const Text('Browse Files'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                            side: BorderSide(
                              color: (isDark ? AppTheme.accentCyan : const Color(0xFF0284C7))
                                  .withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Bar + Source Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 17, color: textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(fontSize: 13, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Search discovered videos...',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: Icon(Icons.cancel_rounded, size: 16, color: textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter: All Media
                    InkWell(
                      onTap: () => setState(() => _activeFilter = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == 0 ? AppTheme.accent : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilter == 0 ? Colors.transparent : borderCol,
                          ),
                        ),
                        child: Text(
                          'All Media (${_libraryFiles.length + recentItems.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _activeFilter == 0 ? const Color(0xFF04131F) : textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Filter: Discovered / Library
                    InkWell(
                      onTap: () => setState(() => _activeFilter = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == 1 ? AppTheme.accent : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilter == 1 ? Colors.transparent : borderCol,
                          ),
                        ),
                        child: Text(
                          'Folders (${_libraryFiles.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _activeFilter == 1 ? const Color(0xFF04131F) : textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Filter: Recent Media
                    InkWell(
                      onTap: () => setState(() => _activeFilter = 2),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == 2 ? AppTheme.accent : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeFilter == 2 ? Colors.transparent : borderCol,
                          ),
                        ),
                        child: Text(
                          'Recent (${recentItems.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _activeFilter == 2 ? const Color(0xFF04131F) : textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: borderCol, height: 1),
                const SizedBox(height: 10),

                // Video List
                Flexible(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.accent),
                        )
                      : candidates.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.movie_outlined, size: 42, color: textSecondary),
                                    const SizedBox(height: 10),
                                    Text(
                                      _activeFilter == 0
                                          ? 'No videos found in Library'
                                          : 'No recent videos found',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      query.isNotEmpty
                                          ? 'Try another search query'
                                          : 'Import a folder or pick video files directly',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _browseFiles,
                                          icon: const Icon(Icons.add_rounded, size: 15),
                                          label: const Text('Browse Video Files'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accent,
                                            foregroundColor: const Color(0xFF04131F),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _importFolder,
                                          icon: const Icon(Icons.create_new_folder_rounded, size: 15),
                                          label: const Text('Import Folder'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: textPrimary,
                                            side: BorderSide(color: borderCol),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: candidates.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = candidates[index];
                                final isQueued = queuedPaths.contains(item.path);
                                final rawName = item.path.split(RegExp(r'[/\\]')).last;
                                final ext = rawName.contains('.')
                                    ? rawName.split('.').last.toUpperCase()
                                    : 'VIDEO';
                                final thumb = ThumbnailService.getCachedThumbnail(item.path);

                                int sizeBytes = 0;
                                try {
                                  sizeBytes = File(item.path).lengthSync();
                                } catch (_) {}

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (!isQueued) {
                                        ref.read(playlistProvider.notifier).addItem(
                                              PlaylistItem(path: item.path, title: item.title),
                                              playImmediately: false,
                                            );
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added to Queue: ${item.title}'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(milliseconds: 1400),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isQueued
                                              ? AppTheme.accent.withValues(alpha: 0.45)
                                              : borderCol,
                                        ),
                                      ),
                                      child: Row(
                                    children: [
                                      // Thumbnail / Badge
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 58,
                                          height: 38,
                                          child: thumb != null
                                              ? Image.file(thumb, fit: BoxFit.cover)
                                              : Container(
                                                  color: isDark ? const Color(0xFF1E2232) : const Color(0xFFCBD5E1),
                                                  child: Center(
                                                    child: Text(
                                                      ext,
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Title & Meta
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF1A202C) : const Color(0xFFE2E8F0),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    ext,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                                                    ),
                                                  ),
                                                ),
                                                if (sizeBytes > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatBytes(sizeBytes),
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Add / In Queue Button
                                      if (isQueued)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: AppTheme.accent.withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_rounded,
                                                  size: 14, color: AppTheme.accent),
                                              const SizedBox(width: 4),
                                              Text(
                                                'In Queue',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            ref.read(playlistProvider.notifier).addItem(
                                                  PlaylistItem(
                                                      path: item.path, title: item.title),
                                                  playImmediately: false,
                                                );
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Added to Queue: ${item.title}'),
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(milliseconds: 1400),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.add_rounded, size: 14),
                                          label: const Text('Add'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                                            side: BorderSide(
                                                color: (isDark ? AppTheme.accent : const Color(0xFF0284C7))
                                                    .withValues(alpha: 0.6)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8)),
                                            textStyle: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                            ),
                ),

                const SizedBox(height: 14),
                Divider(color: borderCol, height: 1),
                const SizedBox(height: 10),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${playlist.items.length} ${playlist.items.length == 1 ? 'video' : 'videos'} currently in active playback queue',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                    if (candidates.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          var addedCount = 0;
                          for (final item in candidates) {
                            if (!queuedPaths.contains(item.path)) {
                              ref.read(playlistProvider.notifier).addItem(
                                    PlaylistItem(path: item.path, title: item.title),
                                    playImmediately: false,
                                  );
                              addedCount++;
                            }
                          }
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $addedCount videos to Queue'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.playlist_add_rounded, size: 16),
                        label: Text('Add All (${candidates.length})'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
