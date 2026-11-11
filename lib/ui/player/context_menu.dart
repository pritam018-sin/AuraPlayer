import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/player_controller.dart';
import 'video_glassy_menu.dart';

class VideoContextMenu {
  static void show(
    BuildContext context,
    Offset position,
    AuraPlayerWrapper playerWrapper,
    WidgetRef ref,
  ) {
    VideoGlassyMenu.show(
      context: context,
      position: position,
      playerWrapper: playerWrapper,
    );
  }
}
