import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'player/player_models.dart';
import 'settings/storage_service.dart';
import 'state/player_provider.dart';
import 'theme/app_theme.dart';
import 'ui/home/home_view.dart';
import 'ui/player/video_surface.dart';
import 'ui/titlebar/custom_titlebar.dart';

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

  // Initialize WindowManager for frameless Apple-style window
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

  // Initialize Persistent Storage
  final storageService = await StorageService.init();

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
    final isPlayingMedia = playlist.currentItem != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isPlayingMedia
          ? VideoSurface(playerWrapper: playerWrapper)
          : Stack(
              children: [
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: 44),
                    child: HomeView(),
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomTitleBar(title: 'AuraPlayer', isVisible: true),
                ),
              ],
            ),
    );
  }
}
