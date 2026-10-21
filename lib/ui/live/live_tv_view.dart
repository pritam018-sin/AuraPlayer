import 'package:flutter/cupertino.dart';
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
    {'id': 'all', 'label': 'All Channels', 'icon': CupertinoIcons.tv},
    {'id': 'fav', 'label': 'Favorites ⭐', 'icon': CupertinoIcons.star_fill},
    {'id': 'sports', 'label': 'Live Sports ⚽', 'icon': CupertinoIcons.sportscourt_fill},
    {'id': 'news', 'label': 'News 24/7 📰', 'icon': CupertinoIcons.news_solid},
    {'id': 'music', 'label': 'Music Hits 🎵', 'icon': CupertinoIcons.music_note_2},
    {'id': 'movies', 'label': 'Movies & Cinema 🎬', 'icon': CupertinoIcons.film_fill},
    {'id': 'kids', 'label': 'Kids & Toons 🧸', 'icon': CupertinoIcons.sparkles},
    {'id': 'documentary', 'label': 'Discovery & Space 🌍', 'icon': CupertinoIcons.globe},
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

  void _showCustomM3uDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: Row(
          children: [
            const Icon(CupertinoIcons.link, size: 20, color: AppTheme.accent),
            const SizedBox(width: 10),
            Text('Open Custom M3U / IPTV URL', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste any public or premium IPTV M3U / M3U8 stream URL:',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppTheme.bodySmall,
              decoration: InputDecoration(
                hintText: 'https://example.com/playlist.m3u8',
                hintStyle: AppTheme.caption.copyWith(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Load Playlist'),
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
    final filteredChannels = _filterChannels(liveState.channels, liveState.favoriteIds);
    final featuredChannel = liveState.channels.isNotEmpty ? liveState.channels.first : null;

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Top Toolbar: Search + Preset Selector + Custom M3U button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.7),
              border: const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
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
                        hintText: 'Search 30,000+ live TV channels (Sports, News, Bollywood, Cinema)...',
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
                const SizedBox(width: 14),

                // Active Source Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 14, color: AppTheme.accentCyan),
                      const SizedBox(width: 8),
                      Text(
                        liveState.activePresetTitle,
                        style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Custom M3U Button
                ElevatedButton.icon(
                  onPressed: _showCustomM3uDialog,
                  icon: const Icon(CupertinoIcons.plus_circle, size: 15),
                  label: const Text('Add M3U URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
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
              color: AppTheme.surfaceSecondary.withValues(alpha: 0.3),
              border: const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _presetChip(
                  label: '⭐ Verified Fast',
                  isSelected: liveState.activePresetTitle == 'Curated Channels',
                  onTap: () => liveNotifier.resetToCurated(),
                ),
                ...LiveService.presets.map((preset) {
                  final isSelected = liveState.activePresetTitle == preset.title;
                  return _presetChip(
                    label: '${preset.icon} ${preset.title}',
                    isSelected: isSelected,
                    onTap: () => liveNotifier.loadPreset(preset),
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
                          Icon(
                            cat['icon'] as IconData,
                            size: 13,
                            color: isSelected ? const Color(0xFF04131F) : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: AppTheme.caption.copyWith(
                              color: isSelected ? const Color(0xFF04131F) : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accent),
                        SizedBox(height: 16),
                        Text('Fetching live IPTV channels from GitHub...', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : filteredChannels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 48, color: AppTheme.textTertiary),
                            const SizedBox(height: 16),
                            Text('No Live Channels Found', style: AppTheme.headline),
                            const SizedBox(height: 8),
                            Text(
                              _onlyFavorites ? 'You have no favorited channels yet. Tap ⭐ to add channels!' : 'Try selecting another category or preset above.',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        children: [
                          // Hero Featured Channel (if available and no search query)
                          if (_searchController.text.isEmpty && featuredChannel != null && !_onlyFavorites)
                            _heroFeaturedCard(featuredChannel),

                          const SizedBox(height: 16),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredChannels.length} Live Channels Available',
                                style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
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
                                  Text('Online HLS Streams', style: AppTheme.caption.copyWith(color: const Color(0xFF22C55E))),
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
                              return _channelCard(ch, isFav);
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
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accentCyan : AppTheme.glassBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.caption.copyWith(
                color: isSelected ? AppTheme.accentCyan : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroFeaturedCard(LiveChannel channel) {
    return FrostedGlass(
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      fillColor: AppTheme.surfaceSecondary.withValues(alpha: 0.7),
      borderColor: AppTheme.accent.withValues(alpha: 0.4),
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
              child: Icon(CupertinoIcons.play_arrow_solid, size: 32, color: Colors.white),
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
                          Text(
                            'LIVE NOW',
                            style: AppTheme.caption.copyWith(
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
                        color: AppTheme.surfaceTertiary,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Text(
                        channel.quality,
                        style: AppTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.accentCyan),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headline.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '${channel.category.toUpperCase()} • ${channel.language} • ${channel.country}',
                  style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Watch Live Button
          ElevatedButton.icon(
            onPressed: () => _playChannel(channel),
            icon: const Icon(CupertinoIcons.play_fill, size: 14),
            label: const Text('WATCH LIVE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelCard(LiveChannel channel, bool isFav) {
    return FrostedGlass(
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      fillColor: AppTheme.surfaceSecondary.withValues(alpha: 0.45),
      borderColor: AppTheme.glassBorder,
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
                    child: Text(
                      'LIVE',
                      style: AppTheme.caption.copyWith(
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
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Text(
                      channel.isHd ? 'HD' : 'SD',
                      style: AppTheme.caption.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ref.read(liveTvProvider.notifier).toggleFavorite(channel.id),
                child: Icon(
                  isFav ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  size: 15,
                  color: isFav ? const Color(0xFFFBBF24) : AppTheme.textTertiary,
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
                  color: AppTheme.surfaceTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(channel.category),
                    size: 18,
                    color: AppTheme.accent,
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
                      style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${channel.category.toUpperCase()} • ${channel.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption.copyWith(fontSize: 10.5, color: AppTheme.textTertiary),
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
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 10, color: AppTheme.accent),
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
        return CupertinoIcons.sportscourt_fill;
      case 'news':
        return CupertinoIcons.news_solid;
      case 'music':
        return CupertinoIcons.music_note_2;
      case 'movies':
        return CupertinoIcons.film_fill;
      case 'kids':
        return CupertinoIcons.sparkles;
      case 'documentary':
        return CupertinoIcons.globe;
      default:
        return CupertinoIcons.tv;
    }
  }
}
