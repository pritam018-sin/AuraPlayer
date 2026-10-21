import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final recents = storage.getRecentFiles();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? recents
        : recents.where((item) => item.title.toLowerCase().contains(query)).toList();

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // History Toolbar
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
                        child: Icon(CupertinoIcons.clock_fill, size: 18, color: Color(0xFF04131F)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Watch History', style: AppTheme.headline),
                        const SizedBox(height: 2),
                        Text(
                          '${recents.length} recently played media files',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Search bar
                    Container(
                      width: 240,
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
                          hintText: 'Search history...',
                          hintStyle: AppTheme.caption.copyWith(color: AppTheme.textTertiary),
                          prefixIcon: const Icon(CupertinoIcons.search, size: 14, color: AppTheme.textSecondary),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (recents.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await storage.clearRecentFiles();
                          setState(() {});
                        },
                        icon: const Icon(CupertinoIcons.trash, size: 15),
                        label: const Text('Clear History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textTertiary,
                          side: const BorderSide(color: AppTheme.glassBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Recents List
          Expanded(
            child: filtered.isEmpty
                ? Center(
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
                            child: Icon(CupertinoIcons.clock, size: 32, color: AppTheme.textTertiary),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          query.isNotEmpty ? 'No Matching History' : 'No Watch History Yet',
                          style: AppTheme.headline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          query.isNotEmpty
                              ? 'Try searching with another keyword'
                              : 'Videos you play will automatically appear here with saved progress so you can resume anytime.',
                          textAlign: TextAlign.center,
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final progress = item.duration.inMilliseconds > 0
                          ? (item.position.inMilliseconds / item.duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: FrostedGlass(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          fillColor: AppTheme.surfaceSecondary.withValues(alpha: 0.45),
                          onTap: () {
                            ref.read(playlistProvider.notifier).setList([
                              PlaylistItem(path: item.path, title: item.title),
                            ]);
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceTertiary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.glassBorder),
                                ),
                                child: const Center(
                                  child: Icon(CupertinoIcons.film, size: 20, color: AppTheme.accent),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Last played ${DateFormat.yMMMd().format(item.lastPlayed)}',
                                          style: AppTheme.caption,
                                        ),
                                        if (item.duration.inSeconds > 0) ...[
                                          const SizedBox(width: 8),
                                          Text('•', style: AppTheme.caption),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Duration: ${_formatDuration(item.duration)}',
                                            style: AppTheme.caption,
                                          ),
                                        ],
                                        if (progress > 0.02) ...[
                                          const SizedBox(width: 8),
                                          Text('•', style: AppTheme.caption),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Resume at ${_formatDuration(item.position)} (${(progress * 100).toInt()}%)',
                                            style: AppTheme.caption.copyWith(color: AppTheme.accent),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (progress > 0.02) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 3,
                                          backgroundColor: AppTheme.surfaceSecondary,
                                          valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(playlistProvider.notifier).setList([
                                    PlaylistItem(path: item.path, title: item.title),
                                  ]);
                                },
                                icon: const Icon(CupertinoIcons.play_fill, size: 12),
                                label: Text(progress > 0.02 ? 'Resume' : 'Play'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
                                ),
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
