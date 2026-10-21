import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../../player/player_controller.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../header/aura_header.dart';
import '../modals/media_info_modal.dart';
import '../modals/open_network_modal.dart';
import '../modals/cinema_studio_modal.dart';
import 'aura_loading_overlay.dart';
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

  // YouTube-style double-tap quick seek state
  int? _seekRippleAmount;
  bool _seekRippleLeft = true;
  Timer? _seekRippleTimer;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _triggerSeekRipple(int seconds, bool isLeft) {
    _seekRippleTimer?.cancel();
    setState(() {
      _seekRippleAmount = seconds;
      _seekRippleLeft = isLeft;
    });
    _seekRippleTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _seekRippleAmount = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _seekRippleTimer?.cancel();
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
        } else {
          CinemaStudioModal.show(context, widget.playerWrapper);
        }
        _onUserActivity();
        break;
      case LogicalKeyboardKey.keyE:
        widget.playerWrapper.stepFrameForward();
        _onUserActivity();
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
                    onDoubleTapDown: (details) {
                      final width = MediaQuery.of(context).size.width;
                      final x = details.localPosition.dx;
                      if (x < width * 0.35) {
                        widget.playerWrapper.seekRelative(const Duration(seconds: -10));
                        _triggerSeekRipple(10, true);
                      } else if (x > width * 0.65) {
                        widget.playerWrapper.seekRelative(const Duration(seconds: 10));
                        _triggerSeekRipple(10, false);
                      } else {
                        if (windowState.isMiniMode) {
                          ref.read(windowControlsProvider.notifier).toggleMiniMode();
                        } else {
                          ref.read(windowControlsProvider.notifier).toggleFullscreen();
                        }
                      }
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
                      child: ValueListenableBuilder<int>(
                        valueListenable: widget.playerWrapper.subtitleConfigRevision,
                        builder: (context, rev, child) {
                          return Video(
                            controller: widget.playerWrapper.videoController,
                            controls: NoVideoControls,
                            subtitleViewConfiguration: widget.playerWrapper.subtitleViewConfiguration,
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Cinematic AuraPlayer Logo Loading & Buffering Overlay
                Positioned.fill(
                  child: AuraLoadingOverlay(
                    playerWrapper: widget.playerWrapper,
                  ),
                ),

                // Double-Tap Quick Seek Visual Ripples (YouTube-style)
                if (_seekRippleAmount != null)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: _seekRippleLeft ? 40 : null,
                    right: !_seekRippleLeft ? 40 : null,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _seekRippleLeft ? CupertinoIcons.gobackward_10 : CupertinoIcons.goforward_10,
                              size: 20,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_seekRippleLeft ? '-' : '+'}${_seekRippleAmount}s',
                              style: AppTheme.body.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Top Aura Header & Bottom Floating Controls (Normal Window & Fullscreen)
                if (!windowState.isMiniMode) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AuraHeader(
                      playerWrapper: widget.playerWrapper,
                      isVisible: _controlsVisible,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: FloatingControls(
                      playerWrapper: widget.playerWrapper,
                      isVisible: _controlsVisible,
                    ),
                  ),
                  if (windowState.isPlaylistOpen)
                    Positioned(
                      top: 42,
                      right: 0,
                      bottom: 0,
                      child: const PlaylistDrawer(),
                    ),
                ] else ...[
                  // Dedicated Mini PiP Overlay
                  Positioned.fill(
                    child: _buildMiniPiPOverlay(windowState),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPiPOverlay(WindowControlsState windowState) {
    final player = widget.playerWrapper.player;
    final isLive = widget.playerWrapper.isLiveStream;
    final title = widget.playerWrapper.currentTitle ?? (isLive ? 'Live Stream' : 'Video');

    return DragToMoveArea(
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Drag Title + Controls
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppTheme.auraGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Image.asset('assets/app_icon.png', width: 14, height: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Exit PiP / Expand Button
                  Tooltip(
                    message: 'Expand Window',
                    child: InkWell(
                      onTap: () => ref.read(windowControlsProvider.notifier).toggleMiniMode(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Close Button
                  Tooltip(
                    message: 'Close',
                    child: InkWell(
                      onTap: () => ref.read(playlistProvider.notifier).stopAndClose(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.clear, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              // Center Controls: Rewind 10s, Hero Play/Pause, Forward 10s
              StreamBuilder<bool>(
                stream: player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? player.state.playing;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          widget.playerWrapper.seekRelative(const Duration(seconds: -10));
                          _onUserActivity();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.gobackward_10, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: () {
                          widget.playerWrapper.playOrPause();
                          _onUserActivity();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.auraGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.45),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                              size: 18,
                              color: const Color(0xFF04131F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: () {
                          widget.playerWrapper.seekRelative(const Duration(seconds: 10));
                          _onUserActivity();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.goforward_10, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Bottom Bar: Progress Indicator & Mute
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: player.stream.position,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? player.state.position;
                        final total = player.state.duration;
                        final frac = total.inMilliseconds > 0
                            ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;
                        return Row(
                          children: [
                            Text(
                              isLive ? 'LIVE' : _formatDuration(pos),
                              style: AppTheme.caption.copyWith(fontSize: 10, color: Colors.white70),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: isLive ? 1.0 : frac,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isLive ? const Color(0xFFEF4444) : AppTheme.accent,
                                  ),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                            if (!isLive) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(total),
                                style: AppTheme.caption.copyWith(fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      widget.playerWrapper.toggleMute();
                      _onUserActivity();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: StreamBuilder<double>(
                      stream: player.stream.volume,
                      builder: (context, snapshot) {
                        final vol = snapshot.data ?? player.state.volume;
                        return Icon(
                          vol == 0 ? CupertinoIcons.volume_off : CupertinoIcons.volume_up,
                          size: 14,
                          color: Colors.white70,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
