import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'player/player_models.dart';
import 'services/thumbnail_service.dart';
import 'settings/storage_service.dart';
import 'state/player_provider.dart';
import 'theme/app_theme.dart';
import 'ui/header/aura_header.dart';
import 'ui/library/library_view.dart';
import 'ui/live/live_tv_view.dart';
import 'ui/player/video_surface.dart';
import 'ui/views/history_view.dart';
import 'ui/views/queue_view.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit playback engine
  MediaKit.ensureInitialized();

  // Initialize Windows Acrylic/Mica effect
  if (Platform.isWindows) {
    try {
      await Window.initialize();
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: const Color(0xCC1A1A1C),
      );
    } catch (_) {}
  }

  // Initialize WindowManager for frameless window with native controls
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(420, 240),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize Persistent Storage & Thumbnail Cache
  final storageService = await StorageService.init();
  await ThumbnailService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: AuraPlayerApp(cliArgs: args),
    ),
  );
}

class AuraPlayerApp extends ConsumerStatefulWidget {
  final List<String> cliArgs;

  const AuraPlayerApp({super.key, required this.cliArgs});

  @override
  ConsumerState<AuraPlayerApp> createState() => _AuraPlayerAppState();
}

class _AuraPlayerAppState extends ConsumerState<AuraPlayerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCommandLineArgs();
    });
  }

  void _handleCommandLineArgs() {
    if (widget.cliArgs.isNotEmpty) {
      final path = widget.cliArgs.first;
      final file = File(path);
      if (file.existsSync()) {
        ref.read(playlistProvider.notifier).setList([
          PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraPlayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuraPlayerHome(),
    );
  }
}

class AuraPlayerHome extends ConsumerWidget {
  const AuraPlayerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerWrapper = ref.watch(playerControllerProvider);
    final playlist = ref.watch(playlistProvider);
    final activeTab = ref.watch(activeTabProvider);
    final isPlayingMedia = playlist.currentItem != null;

    // When playing in Video tab, render full-window video surface with auto-hiding overlay
    if (activeTab == AuraTab.player && isPlayingMedia) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: VideoSurface(playerWrapper: playerWrapper),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Cinema Pro Ambient Projector Lighting & Subtle Theater Glow
          Positioned(
            top: -160,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 140, sigmaY: 100),
                  child: Container(
                    width: 700,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(200),
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.12),
                          AppTheme.accentIndigo.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main View Layout: Header + Active Tab Content
          Column(
            children: [
              AuraHeader(
                playerWrapper: playerWrapper,
                isVisible: true,
              ),
              Expanded(
                child: _buildActiveTabContent(ref, activeTab),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(WidgetRef ref, AuraTab tab) {
    switch (tab) {
      case AuraTab.player:
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppTheme.auraGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.play_arrow_solid, size: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cinema Theater Ready',
                  style: AppTheme.headline.copyWith(letterSpacing: -0.3, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a movie from your library, open a folder, or paste a 4K HDR stream URL.',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => ref.read(activeTabProvider.notifier).setTab(AuraTab.library),
                      icon: const Icon(CupertinoIcons.film, size: 15),
                      label: const Text('Browse Cinema Library'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(activeTabProvider.notifier).setTab(AuraTab.live),
                      icon: const Icon(CupertinoIcons.tv, size: 15, color: Colors.white),
                      label: const Text('Watch Live TV', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.glassBorderHover),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case AuraTab.library:
        return const LibraryView();
      case AuraTab.live:
        return const LiveTvView();
      case AuraTab.playlist:
        return const QueueView();
      case AuraTab.history:
        return const HistoryView();
    }
  }
}
