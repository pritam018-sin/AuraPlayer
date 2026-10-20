import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../player/player_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class MediaInfoModal extends StatelessWidget {
  final AuraPlayerWrapper playerWrapper;

  const MediaInfoModal({super.key, required this.playerWrapper});

  static Future<void> show(BuildContext context, AuraPlayerWrapper wrapper) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => MediaInfoModal(playerWrapper: wrapper),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = playerWrapper.player;
    final state = player.state;
    final tracks = state.tracks;
    final path = playerWrapper.currentFilePath ?? 'None';
    final title = playerWrapper.currentTitle ?? 'No media loaded';
    final duration = state.duration;

    final width = state.width ?? 0;
    final height = state.height ?? 0;
    final resolutionStr = (width > 0 && height > 0) ? '${width}x$height' : 'Unknown';

    final audioInfo = tracks.audio.map((a) => a.title ?? a.language ?? 'Audio Stream ${a.id}').join(', ');
    final subInfo = tracks.subtitle.map((s) => s.title ?? s.language ?? 'Subtitle ${s.id}').join(', ');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          fillColor: AppTheme.surface.withValues(alpha: 0.90),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.info_circle_fill, size: 20, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text('Media Information & Codecs',
                            style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid,
                          size: 20, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoGroup('GENERAL', [
                          _infoRow('Title', title),
                          _infoRow('File Location', path, isSelectable: true),
                          _infoRow('Duration', _formatDuration(duration)),
                          _infoRow('Engine', 'libmpv / media_kit Direct3D11 Native'),
                        ]),
                        const SizedBox(height: 16),

                        _infoGroup('VIDEO STREAM', [
                          _infoRow('Resolution', resolutionStr),
                          _infoRow('Aspect Ratio', playerWrapper.currentAspectRatio ?? 'Default (Auto)'),
                          _infoRow('Video Decoder', 'Hardware Accelerated (H/W Direct3D)'),
                        ]),
                        const SizedBox(height: 16),

                        _infoGroup('AUDIO STREAMS', [
                          _infoRow('Available Tracks', audioInfo.isEmpty ? 'None' : audioInfo),
                          _infoRow('Current Track', state.track.audio.title ?? state.track.audio.language ?? 'Default'),
                          _infoRow('Volume Level', '${state.volume.toInt()}%'),
                        ]),
                        const SizedBox(height: 16),

                        _infoGroup('SUBTITLES', [
                          _infoRow('Available Subtitles', subInfo.isEmpty ? 'None' : subInfo),
                          _infoRow('Current Subtitle', state.track.subtitle.title ?? state.track.subtitle.language ?? 'Off'),
                          _infoRow('Delay Offset', '${(playerWrapper.subtitleDelay.inMilliseconds / 1000).toStringAsFixed(1)}s'),
                        ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppTheme.glassBorder, height: 1),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoGroup(String heading, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600, color: AppTheme.accent)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: isSelectable
                ? SelectableText(
                    value,
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  )
                : Text(
                    value,
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
