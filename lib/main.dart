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
          // AuraMusic-Inspired Ambient Glowing Background Orbs
          Positioned(
            top: -120,
            left: -100,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentCyan.withValues(alpha: 0.10),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppTheme.auraGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.play_arrow_solid, size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text('No Video Playing', style: AppTheme.headline),
              const SizedBox(height: 8),
              Text(
                'Select a video from your library, open a folder, or drop a media file.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(activeTabProvider.notifier).setTab(AuraTab.library),
                icon: const Icon(CupertinoIcons.folder_fill, size: 16),
                label: const Text('Browse Video Library'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
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
