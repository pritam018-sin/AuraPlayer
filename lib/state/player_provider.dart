import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../live/live_catalog.dart';
import '../live/live_models.dart';
import '../live/live_service.dart';
import '../player/player_controller.dart';
import '../player/player_models.dart';
import '../settings/storage_service.dart';

enum AuraTab { player, library, live, playlist, history }

class ActiveTabNotifier extends Notifier<AuraTab> {
  @override
  AuraTab build() => AuraTab.library;

  void setTab(AuraTab tab) {
    state = tab;
  }
}

final activeTabProvider =
    NotifierProvider<ActiveTabNotifier, AuraTab>(ActiveTabNotifier.new);

final liveServiceProvider = Provider<LiveService>((ref) => LiveService());

class LiveTvState {
  final List<LiveChannel> channels;
  final Set<String> favoriteIds;
  final bool isLoading;
  final String activePresetTitle;

  const LiveTvState({
    this.channels = const [],
    this.favoriteIds = const {},
    this.isLoading = false,
    this.activePresetTitle = 'Curated Channels',
  });

  LiveTvState copyWith({
    List<LiveChannel>? channels,
    Set<String>? favoriteIds,
    bool? isLoading,
    String? activePresetTitle,
  }) {
    return LiveTvState(
      channels: channels ?? this.channels,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      activePresetTitle: activePresetTitle ?? this.activePresetTitle,
    );
  }
}

class LiveTvNotifier extends Notifier<LiveTvState> {
  late final LiveService _service;

  @override
  LiveTvState build() {
    _service = ref.watch(liveServiceProvider);
    _init();
    return const LiveTvState(channels: LiveCatalog.defaultChannels);
  }

  Future<void> _init() async {
    final favs = await _service.getFavoriteIds();
    state = state.copyWith(favoriteIds: favs);
  }

  Future<void> loadPreset(LivePreset preset) async {
    state = state.copyWith(isLoading: true, activePresetTitle: preset.title);
    final fetched = await _service.fetchM3u(preset.url);
    if (fetched.isNotEmpty) {
      state = state.copyWith(channels: fetched, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadCustomM3u(String url) async {
    state = state.copyWith(isLoading: true, activePresetTitle: 'Custom Playlist');
    final fetched = await _service.fetchM3u(url);
    if (fetched.isNotEmpty) {
      state = state.copyWith(channels: fetched, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void resetToCurated() {
    state = state.copyWith(
      channels: LiveCatalog.defaultChannels,
      activePresetTitle: 'Curated Channels',
    );
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
    final favs = await _service.getFavoriteIds();
    state = state.copyWith(favoriteIds: favs);
  }
}

final liveTvProvider =
    NotifierProvider<LiveTvNotifier, LiveTvState>(LiveTvNotifier.new);

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main');
});

final playerControllerProvider = Provider<AuraPlayerWrapper>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final wrapper = AuraPlayerWrapper(storageService: storage);
  ref.onDispose(() => wrapper.dispose());
  return wrapper;
});

class PlaylistState {
  final List<PlaylistItem> items;
  final int currentIndex;

  const PlaylistState({
    this.items = const [],
    this.currentIndex = -1,
  });

  bool get hasItems => items.isNotEmpty;
  bool get hasNext => currentIndex >= 0 && currentIndex < items.length - 1;
  bool get hasPrev => currentIndex > 0;
  PlaylistItem? get currentItem =>
      (currentIndex >= 0 && currentIndex < items.length) ? items[currentIndex] : null;

  PlaylistState copyWith({
    List<PlaylistItem>? items,
    int? currentIndex,
  }) {
    return PlaylistState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class PlaylistNotifier extends Notifier<PlaylistState> {
  @override
  PlaylistState build() => const PlaylistState();

  void setList(List<PlaylistItem> items, {int initialIndex = 0}) {
    state = PlaylistState(items: items, currentIndex: initialIndex);
    if (items.isNotEmpty && initialIndex >= 0 && initialIndex < items.length) {
      ref.read(playerControllerProvider).openFile(items[initialIndex].path);
      ref.read(activeTabProvider.notifier).setTab(AuraTab.player);
    }
  }

  void addItem(PlaylistItem item, {bool playImmediately = false}) {
    final updated = [...state.items, item];
    if (playImmediately || state.currentIndex == -1) {
      state = state.copyWith(items: updated, currentIndex: updated.length - 1);
      ref.read(playerControllerProvider).openFile(item.path);
      ref.read(activeTabProvider.notifier).setTab(AuraTab.player);
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items]..removeAt(index);
    var newIdx = state.currentIndex;
    if (index == state.currentIndex) {
      if (updated.isEmpty) {
        newIdx = -1;
        ref.read(playerControllerProvider).stop();
        ref.read(activeTabProvider.notifier).setTab(AuraTab.library);
      } else {
        newIdx = index >= updated.length ? updated.length - 1 : index;
        ref.read(playerControllerProvider).openFile(updated[newIdx].path);
      }
    } else if (index < state.currentIndex) {
      newIdx--;
    }
    state = state.copyWith(items: updated, currentIndex: newIdx);
  }

  void playIndex(int index) {
    if (index >= 0 && index < state.items.length) {
      state = state.copyWith(currentIndex: index);
      ref.read(playerControllerProvider).openFile(state.items[index].path);
      ref.read(activeTabProvider.notifier).setTab(AuraTab.player);
    }
  }

  void next() {
    if (state.hasNext) {
      playIndex(state.currentIndex + 1);
    }
  }

  void prev() {
    if (state.hasPrev) {
      playIndex(state.currentIndex - 1);
    }
  }
}

final playlistProvider =
    NotifierProvider<PlaylistNotifier, PlaylistState>(PlaylistNotifier.new);

// Window Mode State
class WindowControlsState {
  final bool isAlwaysOnTop;
  final bool isMiniMode;
  final bool isFullscreen;
  final bool isPlaylistOpen;

  const WindowControlsState({
    this.isAlwaysOnTop = false,
    this.isMiniMode = false,
    this.isFullscreen = false,
    this.isPlaylistOpen = false,
  });

  WindowControlsState copyWith({
    bool? isAlwaysOnTop,
    bool? isMiniMode,
    bool? isFullscreen,
    bool? isPlaylistOpen,
  }) {
    return WindowControlsState(
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      isMiniMode: isMiniMode ?? this.isMiniMode,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isPlaylistOpen: isPlaylistOpen ?? this.isPlaylistOpen,
    );
  }
}

class WindowControlsNotifier extends Notifier<WindowControlsState> {
  @override
  WindowControlsState build() => const WindowControlsState();

  Future<void> toggleAlwaysOnTop() async {
    final next = !state.isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(next);
    state = state.copyWith(isAlwaysOnTop: next);
  }

  Future<void> toggleFullscreen() async {
    final isFull = await windowManager.isFullScreen();
    final next = !isFull;
    await windowManager.setFullScreen(next);
    state = state.copyWith(isFullscreen: next);
  }

  Future<void> toggleMiniMode() async {
    final next = !state.isMiniMode;
    if (next) {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(const Size(440, 250));
    } else {
      await windowManager.setAlwaysOnTop(state.isAlwaysOnTop);
      await windowManager.setSize(const Size(1280, 720));
    }
    state = state.copyWith(isMiniMode: next);
  }

  void togglePlaylist() {
    state = state.copyWith(isPlaylistOpen: !state.isPlaylistOpen);
  }

  void closePlaylist() {
    if (state.isPlaylistOpen) {
      state = state.copyWith(isPlaylistOpen: false);
    }
  }
}

final windowControlsProvider =
    NotifierProvider<WindowControlsNotifier, WindowControlsState>(
        WindowControlsNotifier.new);
