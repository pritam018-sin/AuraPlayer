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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.35);

    final storage = ref.watch(storageServiceProvider);
    final recents = storage.getRecentFiles();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? recents
        : recents.where((item) => item.title.toLowerCase().contains(query)).toList();

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // History Toolbar
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
                        child: Icon(Icons.history_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Watch History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${recents.length} recently played media files',
                          style: TextStyle(fontSize: 12, color: textSecondary),
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
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderCol),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search history...',
                          hintStyle: TextStyle(
                            color: textSecondary.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, size: 16, color: textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.cancel_rounded, size: 15, color: textSecondary),
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
                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                        label: const Text('Clear History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderCol),
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
                            color: cardBg,
                            border: Border.all(color: borderCol),
                          ),
                          child: Center(
                            child: Icon(Icons.history_rounded, size: 36, color: textSecondary),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          query.isNotEmpty ? 'No Matching History' : 'No Watch History Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          query.isNotEmpty
                              ? 'Try searching with another keyword'
                              : 'Videos you play will automatically appear here with saved progress so you can resume anytime.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
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
                          fillColor: cardBg,
                          borderColor: borderCol,
                          blur: 35,
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
                                  color: isDark ? const Color(0xFF1E2232) : const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Center(
                                  child: Icon(Icons.movie_rounded, size: 22, color: isDark ? AppTheme.accent : const Color(0xFF0284C7)),
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
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Last played ${DateFormat.yMMMd().format(item.lastPlayed)}',
                                          style: TextStyle(fontSize: 11, color: textSecondary),
                                        ),
                                        if (item.duration.inSeconds > 0) ...[
                                          const SizedBox(width: 8),
                                          Text('•', style: TextStyle(color: textSecondary)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Duration: ${_formatDuration(item.duration)}',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                        ],
                                        if (progress > 0.02) ...[
                                          const SizedBox(width: 8),
                                          Text('•', style: TextStyle(color: textSecondary)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Resume at ${_formatDuration(item.position)} (${(progress * 100).toInt()}%)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                          backgroundColor: isDark ? const Color(0xFF1E2232) : const Color(0xFFE2E8F0),
                                          valueColor: AlwaysStoppedAnimation(
                                            isDark ? AppTheme.accent : const Color(0xFF0284C7),
                                          ),
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
                                icon: const Icon(Icons.play_arrow_rounded, size: 15),
                                label: Text(progress > 0.02 ? 'Resume' : 'Play'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  foregroundColor: const Color(0xFF04131F),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
