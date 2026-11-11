import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../live/live_models.dart';
import '../../live/live_service.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class LiveTvView extends ConsumerStatefulWidget {
  const LiveTvView({super.key});

  @override
  ConsumerState<LiveTvView> createState() => _LiveTvViewState();
}

class _LiveTvViewState extends ConsumerState<LiveTvView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _onlyFavorites = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All Channels', 'icon': Icons.tv_rounded},
    {'id': 'fav', 'label': 'Favorites ⭐', 'icon': Icons.star_rounded},
    {'id': 'sports', 'label': 'Live Sports ⚽', 'icon': Icons.sports_soccer_rounded},
    {'id': 'news', 'label': 'News 24/7 📰', 'icon': Icons.newspaper_rounded},
    {'id': 'music', 'label': 'Music Hits 🎵', 'icon': Icons.music_note_rounded},
    {'id': 'movies', 'label': 'Movies & Cinema 🎬', 'icon': Icons.movie_rounded},
    {'id': 'kids', 'label': 'Kids & Toons 🧸', 'icon': Icons.child_care_rounded},
    {'id': 'documentary', 'label': 'Discovery & Space 🌍', 'icon': Icons.public_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playChannel(LiveChannel channel) {
    ref.read(playlistProvider.notifier).setList([
      PlaylistItem(
        path: channel.streamUrl,
        title: '${channel.name} [LIVE]',
      ),
    ]);
  }

  void _showCustomM3uDialog(bool isDark) {
    final controller = TextEditingController();
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final dialogBg = isDark ? AppTheme.surface : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderCol),
        ),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, size: 20, color: AppTheme.accent),
            const SizedBox(width: 10),
            Text(
              'Open Custom M3U / IPTV URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste any public or premium IPTV M3U / M3U8 stream URL:',
              style: TextStyle(fontSize: 12.5, color: textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'https://example.com/playlist.m3u8',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
                filled: true,
                fillColor: isDark ? AppTheme.surfaceSecondary : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderCol),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(liveTvProvider.notifier).loadCustomM3u(url);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF04131F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Load Playlist', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<LiveChannel> _filterChannels(List<LiveChannel> all, Set<String> favIds) {
    var list = all;
    if (_onlyFavorites) {
      list = list.where((c) => favIds.contains(c.id)).toList();
    } else if (_selectedCategory != 'all') {
      list = list.where((c) => c.category.toLowerCase() == _selectedCategory).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.language.toLowerCase().contains(query) ||
          c.country.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveTvProvider);
    final liveNotifier = ref.read(liveTvProvider.notifier);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.35);

    final filteredChannels = _filterChannels(liveState.channels, liveState.favoriteIds);
    final featuredChannel = liveState.channels.isNotEmpty ? liveState.channels.first : null;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Top Toolbar: Search + Preset Selector + Custom M3U button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surface.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.38),
              border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
            ),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: Container(
                    height: 38,
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
                        hintText: 'Search 30,000+ live TV channels (Sports, News, Bollywood, Cinema)...',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Active Source Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings_input_antenna_rounded, size: 15, color: AppTheme.accentCyan),
                      const SizedBox(width: 8),
                      Text(
                        liveState.activePresetTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Custom M3U Button
                ElevatedButton.icon(
                  onPressed: () => _showCustomM3uDialog(isDark),
                  icon: const Icon(Icons.add_link_rounded, size: 16),
                  label: const Text('Add M3U URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: const Color(0xFF04131F),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // GitHub IPTV-ORG Presets Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceSecondary.withValues(alpha: 0.20)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.40),
              border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _presetChip(
                  label: '⭐ Verified Fast',
                  isSelected: liveState.activePresetTitle == 'Curated Channels',
                  onTap: () => liveNotifier.resetToCurated(),
                  isDark: isDark,
                ),
                ...LiveService.presets.map((preset) {
                  final isSelected = liveState.activePresetTitle == preset.title;
                  return _presetChip(
                    label: '${preset.icon} ${preset.title}',
                    isSelected: isSelected,
                    onTap: () => liveNotifier.loadPreset(preset),
                    isDark: isDark,
                  );
                }),
              ],
            ),
          ),

          // Genre / Category Tag Carousel
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final id = cat['id'] as String;
                final isSelected = id == 'fav' ? _onlyFavorites : (_selectedCategory == id && !_onlyFavorites);

                return Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (id == 'fav') {
                          _onlyFavorites = !_onlyFavorites;
                        } else {
                          _onlyFavorites = false;
                          _selectedCategory = id;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.auraGradient : null,
                        color: isSelected ? null : cardBg,
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
                          Icon(
                            cat['icon'] as IconData,
                            size: 14,
                            color: isSelected ? const Color(0xFF04131F) : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? const Color(0xFF04131F) : textSecondary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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

          // Main Channels Grid / Content Area
          Expanded(
            child: liveState.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.accent),
                        const SizedBox(height: 16),
                        Text('Fetching live IPTV channels...', style: TextStyle(color: textSecondary)),
                      ],
                    ),
                  )
                : filteredChannels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tv_off_rounded, size: 48, color: textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'No Live Channels Found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _onlyFavorites ? 'You have no favorited channels yet. Tap ⭐ to add channels!' : 'Try selecting another category or preset above.',
                              style: TextStyle(fontSize: 12.5, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        children: [
                          // Hero Featured Channel (if available and no search query)
                          if (_searchController.text.isEmpty && featuredChannel != null && !_onlyFavorites)
                            _heroFeaturedCard(featuredChannel, isDark, textPrimary, textSecondary, borderCol),

                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredChannels.length} Live Channels Available',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Online HLS Streams',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Channels Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 280,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filteredChannels.length,
                            itemBuilder: (context, index) {
                              final ch = filteredChannels[index];
                              final isFav = liveState.favoriteIds.contains(ch.id);
                              return _channelCard(ch, isFav, isDark, textPrimary, textSecondary, borderCol, cardBg);
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentCyan.withValues(alpha: isDark ? 0.25 : 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accentCyan : borderCol,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? (isDark ? AppTheme.accentCyan : const Color(0xFF0284C7)) : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroFeaturedCard(
    LiveChannel channel,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
  ) {
    return FrostedGlass(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      fillColor: isDark
          ? const Color(0xFF131522).withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.65),
      borderColor: AppTheme.accent.withValues(alpha: 0.5),
      blur: 35,
      onTap: () => _playChannel(channel),
      child: Row(
        children: [
          // Live Glow Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.auraGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.play_arrow_rounded, size: 36, color: Color(0xFF04131F)),
            ),
          ),
          const SizedBox(width: 20),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE NOW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2232) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderCol),
                      ),
                      child: Text(
                        channel.quality,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${channel.category.toUpperCase()} • ${channel.language} • ${channel.country}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),

          // Watch Live Button
          ElevatedButton.icon(
            onPressed: () => _playChannel(channel),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('WATCH LIVE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF04131F),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelCard(
    LiveChannel channel,
    bool isFav,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderCol,
    Color cardBg,
  ) {
    return FrostedGlass(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      fillColor: cardBg,
      borderColor: borderCol,
      blur: 35,
      onTap: () => _playChannel(channel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: LIVE badge + Quality badge + Favorite button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderCol),
                    ),
                    child: Text(
                      channel.isHd ? 'HD' : 'SD',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.accentCyan : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ref.read(liveTvProvider.notifier).toggleFavorite(channel.id),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 17,
                  color: isFav ? const Color(0xFFFBBF24) : textSecondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Channel Emblem
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2232) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(channel.category),
                    size: 19,
                    color: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${channel.category.toUpperCase()} • ${channel.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Play action bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Watch Channel',
                  style: TextStyle(
                    color: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isDark ? AppTheme.accent : const Color(0xFF0284C7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'movies':
        return Icons.movie_rounded;
      case 'kids':
        return Icons.child_care_rounded;
      case 'documentary':
        return Icons.public_rounded;
      default:
        return Icons.live_tv_rounded;
    }
  }
}
