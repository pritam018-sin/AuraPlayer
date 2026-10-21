import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../player/player_controller.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../header/aura_header.dart';
import '../modals/media_info_modal.dart';
import '../modals/open_network_modal.dart';
import 'context_menu.dart';
import 'floating_controls.dart';
import 'playlist_drawer.dart';

class VideoSurface extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const VideoSurface({super.key, required this.playerWrapper});

  @override
  ConsumerState<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends ConsumerState<VideoSurface> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onUserActivity() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _startHideTimer();
  }

  Future<void> _pickFileShortcut() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ref.read(playlistProvider.notifier).setList([
        PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
      ]);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isControl = HardwareKeyboard.instance.isControlPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        widget.playerWrapper.playOrPause();
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyS:
        if (isShift) {
          widget.playerWrapper.takeSnapshot().then((path) {
            if (mounted && path != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Snapshot saved: ${path.split(RegExp(r'[/\\]')).last}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        } else {
          ref.read(playlistProvider.notifier).stopAndClose();
        }
        _onUserActivity();
        break;
      case LogicalKeyboardKey.arrowLeft:
        final delta = isShift ? const Duration(seconds: -30) : const Duration(seconds: -5);
        widget.playerWrapper.seekRelative(delta);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.arrowRight:
        final delta = isShift ? const Duration(seconds: 30) : const Duration(seconds: 5);
        widget.playerWrapper.seekRelative(delta);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.arrowUp:
        widget.playerWrapper.changeVolumeRelative(5.0);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.arrowDown:
        widget.playerWrapper.changeVolumeRelative(-5.0);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyM:
        widget.playerWrapper.toggleMute();
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyF:
        ref.read(windowControlsProvider.notifier).toggleFullscreen();
        _onUserActivity();
        break;
      case LogicalKeyboardKey.escape:
        final windowState = ref.read(windowControlsProvider);
        if (windowState.isFullscreen) {
          ref.read(windowControlsProvider.notifier).toggleFullscreen();
        } else {
          ref.read(playlistProvider.notifier).stopAndClose();
        }
        _onUserActivity();
        break;
      case LogicalKeyboardKey.bracketLeft:
        final curRate = widget.playerWrapper.player.state.rate;
        widget.playerWrapper.setRate(curRate - 0.25);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.bracketRight:
        final curRate = widget.playerWrapper.player.state.rate;
        widget.playerWrapper.setRate(curRate + 0.25);
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyP:
        ref.read(playlistProvider.notifier).prev();
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyN:
        if (isControl) {
          OpenNetworkModal.show(context);
        } else {
          ref.read(playlistProvider.notifier).next();
        }
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyO:
        if (isControl) {
          _pickFileShortcut();
        }
        break;
      case LogicalKeyboardKey.keyL:
        if (isControl) {
          ref.read(windowControlsProvider.notifier).togglePlaylist();
        }
        break;
      case LogicalKeyboardKey.keyI:
        if (isControl) {
          MediaInfoModal.show(context, widget.playerWrapper);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowState = ref.watch(windowControlsProvider);

    // Hide cursor in fullscreen when controls are auto-hidden
    final mouseCursor = (windowState.isFullscreen && !_controlsVisible)
        ? SystemMouseCursors.none
        : SystemMouseCursors.basic;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: MouseRegion(
        cursor: mouseCursor,
        onHover: (_) => _onUserActivity(),
        onEnter: (_) => _onUserActivity(),
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              // Mouse wheel controls volume
              final delta = pointerSignal.scrollDelta.dy > 0 ? -4.0 : 4.0;
              widget.playerWrapper.changeVolumeRelative(delta);
              _onUserActivity();
            }
          },
          child: DropTarget(
            onDragDone: (details) {
              final paths = details.files.map((f) => f.path).toList();
              if (paths.isNotEmpty) {
                final path = paths.first;
                ref.read(playlistProvider.notifier).addItem(
                      PlaylistItem(path: path, title: path.split(RegExp(r'[/\\]')).last),
                      playImmediately: true,
                    );
              }
            },
            child: Stack(
              children: [
                // MediaKit Video Surface filling window
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.playerWrapper.playOrPause();
                      _onUserActivity();
                    },
                    onDoubleTap: () {
                      ref.read(windowControlsProvider.notifier).toggleFullscreen();
                      _onUserActivity();
                    },
                    onSecondaryTapDown: (details) {
                      VideoContextMenu.show(
                        context,
                        details.globalPosition,
                        widget.playerWrapper,
                        ref,
                      );
                    },
                    child: Center(
                      child: Video(
                        controller: widget.playerWrapper.videoController,
                        controls: NoVideoControls,
                      ),
                    ),
                  ),
                ),

                // Top Aura Header with VLC menus & Windows controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AuraHeader(
                    playerWrapper: widget.playerWrapper,
                    isVisible: _controlsVisible,
                  ),
                ),

                // Bottom Floating Controls Pill
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FloatingControls(
                    playerWrapper: widget.playerWrapper,
                    isVisible: _controlsVisible,
                  ),
                ),

                // Slide-in Playlist Drawer
                if (windowState.isPlaylistOpen)
                  Positioned(
                    top: 42,
                    right: 0,
                    bottom: 0,
                    child: const PlaylistDrawer(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
