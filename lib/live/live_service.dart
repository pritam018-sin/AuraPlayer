import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'live_models.dart';

class LivePreset {
  final String title;
  final String url;
  final String icon;

  const LivePreset({required this.title, required this.url, required this.icon});
}

class LiveService {
  static const List<LivePreset> presets = [
    LivePreset(
      title: 'India Live (iptv-org)',
      url: 'https://iptv-org.github.io/iptv/countries/in.m3u',
      icon: '🇮🇳',
    ),
    LivePreset(
      title: 'Live Sports HD',
      url: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
      icon: '⚽',
    ),
    LivePreset(
      title: '24/7 News HD',
      url: 'https://iptv-org.github.io/iptv/categories/news.m3u',
      icon: '📰',
    ),
    LivePreset(
      title: 'Music TV Hits',
      url: 'https://iptv-org.github.io/iptv/categories/music.m3u',
      icon: '🎵',
    ),
    LivePreset(
      title: 'Movies & Cinema',
      url: 'https://iptv-org.github.io/iptv/categories/movies.m3u',
      icon: '🎬',
    ),
    LivePreset(
      title: 'Kids & Cartoons',
      url: 'https://iptv-org.github.io/iptv/categories/kids.m3u',
      icon: '🧸',
    ),
    LivePreset(
      title: 'Global Master Feed',
      url: 'https://iptv-org.github.io/iptv/index.m3u',
      icon: '🌍',
    ),
  ];

  static const String _favoritesKey = 'aura_live_favorites';

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    if (list.contains(channelId)) {
      list.remove(channelId);
    } else {
      list.add(channelId);
    }
    await prefs.setStringList(_favoritesKey, list);
  }

  Future<List<LiveChannel>> fetchM3u(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return parseM3u(res.body);
      }
    } catch (_) {}
    return [];
  }

  List<LiveChannel> parseM3u(String content) {
    final lines = const LineSplitter().convert(content);
    final channels = <LiveChannel>[];

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentId;

    final infoRegex = RegExp(r'#EXTINF:[^,]*,(.*)');
    final logoRegex = RegExp(r'tvg-logo="([^"]*)"');
    final nameRegex = RegExp(r'tvg-name="([^"]*)"');
    final groupRegex = RegExp(r'group-title="([^"]*)"');
    final idRegex = RegExp(r'tvg-id="([^"]*)"');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#EXTINF:')) {
        final matchInfo = infoRegex.firstMatch(trimmed);
        currentName = matchInfo?.group(1)?.trim();

        final matchName = nameRegex.firstMatch(trimmed);
        if (matchName != null && matchName.group(1)!.isNotEmpty) {
          currentName = matchName.group(1)!.trim();
        }

        final matchLogo = logoRegex.firstMatch(trimmed);
        currentLogo = matchLogo?.group(1)?.trim();

        final matchGroup = groupRegex.firstMatch(trimmed);
        currentGroup = matchGroup?.group(1)?.trim();

        final matchId = idRegex.firstMatch(trimmed);
        currentId = matchId?.group(1)?.trim();
      } else if (!trimmed.startsWith('#') && (trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
        if (currentName != null && currentName.isNotEmpty) {
          final id = currentId ?? 'ch_${channels.length}_${currentName.hashCode}';
          final group = currentGroup?.toLowerCase() ?? 'general';

          var category = 'general';
          if (group.contains('sport')) {
            category = 'sports';
          } else if (group.contains('news')) {
            category = 'news';
          } else if (group.contains('music')) {
            category = 'music';
          } else if (group.contains('movie') || group.contains('cinema')) {
            category = 'movies';
          } else if (group.contains('kid') || group.contains('animation')) {
            category = 'kids';
          } else if (group.contains('doc') || group.contains('science')) {
            category = 'documentary';
          }

          final isHd = currentName.toUpperCase().contains('HD') || currentName.toUpperCase().contains('1080');

          channels.add(
            LiveChannel(
              id: id,
              name: currentName,
              streamUrl: trimmed,
              logoUrl: currentLogo,
              category: category,
              country: 'LIVE',
              language: 'Live Broadcast',
              isHd: isHd,
              quality: isHd ? '1080p HD' : 'HD',
            ),
          );
        }
        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentId = null;
      }
    }

    return channels;
  }
}
