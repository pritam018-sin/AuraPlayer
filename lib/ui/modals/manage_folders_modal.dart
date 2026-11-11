import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class ManageFoldersModal extends ConsumerStatefulWidget {
  final Future<void> Function()? onFoldersChanged;

  const ManageFoldersModal({super.key, this.onFoldersChanged});

  static Future<void> show(BuildContext context, {Future<void> Function()? onFoldersChanged}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: ManageFoldersModal(onFoldersChanged: onFoldersChanged),
      ),
    );
  }

  @override
  ConsumerState<ManageFoldersModal> createState() => _ManageFoldersModalState();
}

class _ManageFoldersModalState extends ConsumerState<ManageFoldersModal> {
  Future<void> _addNewFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && mounted) {
      final storage = ref.read(storageServiceProvider);
      await storage.addImportedFolder(path);
      if (widget.onFoldersChanged != null) {
        await widget.onFoldersChanged!();
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported folder: ${path.split(RegExp(r'[/\\]')).last}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeFolder(String folderPath) async {
    final storage = ref.read(storageServiceProvider);
    await storage.removeImportedFolder(folderPath);
    if (widget.onFoldersChanged != null) {
      await widget.onFoldersChanged!();
    }
    setState(() {});
    if (mounted) {
      final name = folderPath.split(RegExp(r'[/\\]')).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed folder from library: $name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _countVideosInFolder(String folderPath) {
    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) return 0;
      final videoExts = ['.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v'];
      int count = 0;
      void walk(Directory d, int depth) {
        if (depth > 5) return;
        try {
          for (final entity in d.listSync(recursive: false, followLinks: false)) {
            if (entity is File) {
              final lower = entity.path.toLowerCase();
              if (videoExts.any((ext) => lower.endsWith(ext))) {
                count++;
              }
            } else if (entity is Directory) {
              final name = entity.path.split(RegExp(r'[/\\]')).last;
              if (!name.startsWith('.') && !name.startsWith(r'$') && name != 'node_modules') {
                walk(entity, depth + 1);
              }
            }
          }
        } catch (_) {}
      }
      walk(dir, 0);
      return count;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final folders = storage.getImportedFolders();
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0C101A).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.65);
    final itemBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.70);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 22,
          padding: const EdgeInsets.all(24),
          blur: 35,
          fillColor: cardBg,
          borderColor: borderCol,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
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
                            child: Icon(Icons.folder_rounded, size: 19, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Library Folders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${folders.length} imported media source ${folders.length == 1 ? 'folder' : 'folders'}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: borderCol, height: 1),
                const SizedBox(height: 14),

                // Folder List
                Flexible(
                  child: folders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.create_new_folder_rounded,
                                    size: 44, color: textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No Folders Imported',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Import folders containing your movies or videos to build your offline library.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: folders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final name = folder.split(RegExp(r'[/\\]')).last;
                            final videoCount = _countVideosInFolder(folder);
                            final exists = Directory(folder).existsSync();

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: exists
                                          ? AppTheme.accent.withValues(alpha: 0.15)
                                          : Colors.redAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: exists
                                            ? AppTheme.accent.withValues(alpha: 0.3)
                                            : Colors.redAccent.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        exists
                                            ? Icons.folder_rounded
                                            : Icons.folder_off_rounded,
                                        size: 19,
                                        color: exists ? AppTheme.accent : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name.isEmpty ? folder : name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E2232) : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$videoCount videos',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          folder,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Actions: Open Explorer & Remove
                                  if (exists)
                                    IconButton(
                                      tooltip: 'Open in File Explorer',
                                      icon: Icon(Icons.open_in_new_rounded,
                                          size: 18, color: textSecondary),
                                      onPressed: () {
                                        Process.run('explorer.exe', [folder]);
                                      },
                                    ),
                                  IconButton(
                                    tooltip: 'Remove Folder from Library',
                                    icon: const Icon(Icons.delete_outline_rounded,
                                        size: 19, color: Color(0xFFF43F5E)),
                                    onPressed: () => _removeFolder(folder),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 18),
                Divider(color: borderCol, height: 1),
                const SizedBox(height: 14),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Removing a folder only removes it from AuraPlayer.\nYour actual video files will NOT be deleted.',
                      style: TextStyle(fontSize: 10.5, color: textSecondary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addNewFolder,
                      icon: const Icon(Icons.create_new_folder_rounded, size: 16),
                      label: const Text('Add Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF04131F),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
