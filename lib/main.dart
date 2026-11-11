import 'dart:io';
import 'dart:ui';
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
import 'ui/home/home_view.dart';
import 'ui/library/library_view.dart';
import 'ui/live/live_tv_view.dart';
import 'ui/player/in_app_mini_player.dart';
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
    if (widget.cliArgs.isEmpty) return;

    // Check combined arguments in case Windows passed unquoted path with spaces
    final combined = widget.cliArgs.join(' ').trim();
    final candidateArgs = [combined, ...widget.cliArgs];

    for (final rawArg in candidateArgs) {
      var clean = rawArg.trim();
      if ((clean.startsWith('"') && clean.endsWith('"')) ||
          (clean.startsWith("'") && clean.endsWith("'"))) {
        clean = clean.substring(1, clean.length - 1).trim();
      }
      if (clean.startsWith('file://')) {
        try {
          clean = Uri.decodeFull(Uri.parse(clean).toFilePath());
        } catch (_) {}
      }

      if (clean.isEmpty) continue;

      File file = File(clean);
      if (!file.existsSync()) {
        file = File(file.absolute.path);
      }

      if (file.existsSync()) {
        ref.read(playlistProvider.notifier).setList([
          PlaylistItem(path: file.path, title: file.path.split(RegExp(r'[/\\]')).last),
        ]);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AuraPlayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isPlayingMedia = playlist.currentItem != null;

    // When playing in Video tab, render full-window video surface with auto-hiding overlay
    if (activeTab == AuraTab.player && isPlayingMedia) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: VideoSurface(playerWrapper: playerWrapper),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : AppTheme.lightBackground,
      body: Stack(
        children: [
          // Dynamic Multi-Orb Ambient Glass Light Mesh (gives BackdropFilter real frosted refraction)
          Positioned(
            top: -120,
            left: -80,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(
                  width: 520,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppTheme.accent.withValues(alpha: 0.22)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -100,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 130, sigmaY: 130),
                child: Container(
                  width: 500,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppTheme.accentPurple.withValues(alpha: 0.20)
                        : const Color(0xFFA78BFA).withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 130, sigmaY: 130),
                child: Container(
                  width: 440,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.14)
                        : const Color(0xFF67E8F9).withValues(alpha: 0.20),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: 200,
            right: 200,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(160),
                    color: isDark
                        ? AppTheme.accentIndigo.withValues(alpha: 0.16)
                        : const Color(0xFF2DD4BF).withValues(alpha: 0.22),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<AuraTab>(activeTab),
                    child: _buildActiveTabContent(ref, activeTab),
                  ),
                ),
              ),
            ],
          ),

          // YouTube-style Floating In-App Miniplayer when browsing tabs while playing
          if (isPlayingMedia && activeTab != AuraTab.player)
            InAppMiniPlayer(playerWrapper: playerWrapper),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(WidgetRef ref, AuraTab tab) {
    switch (tab) {
      case AuraTab.player:
        return const HomeView();
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
