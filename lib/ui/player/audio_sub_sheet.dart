import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../player/player_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class AudioSubtitleSheet extends StatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const AudioSubtitleSheet({super.key, required this.playerWrapper});

  static Future<void> show(BuildContext context, AuraPlayerWrapper wrapper) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AudioSubtitleSheet(playerWrapper: wrapper),
    );
  }

  @override
  State<AudioSubtitleSheet> createState() => _AudioSubtitleSheetState();
}

class _AudioSubtitleSheetState extends State<AudioSubtitleSheet> {
  Future<void> _pickSubtitle() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'vtt', 'sub'],
    );
    if (res != null && res.files.single.path != null) {
      await widget.playerWrapper.loadExternalSubtitle(res.files.single.path!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0.0 s';
    final sign = ms > 0 ? '+' : '';
    return '$sign${(ms / 1000).toStringAsFixed(1)} s';
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.playerWrapper.player;
    final tracks = player.state.tracks;
    final currentAudio = player.state.track.audio;
    final currentSub = player.state.track.subtitle;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          fillColor: AppTheme.surface.withValues(alpha: 0.85),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
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
                        const Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text('Tracks & Subtitles', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20, color: AppTheme.textSecondary),
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
                        // Audio Tracks
                        Text('AUDIO TRACK', style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (tracks.audio.isEmpty)
                          Text('No alternate audio tracks available', style: AppTheme.caption)
                        else
                          ...tracks.audio.map((t) {
                            final isSelected = t.id == currentAudio.id;
                            final label = (t.title?.isNotEmpty ?? false)
                                ? t.title!
                                : (t.language?.isNotEmpty ?? false ? t.language! : 'Track ${t.id}');
                            return _trackTile(
                              title: label,
                              isSelected: isSelected,
                              onTap: () {
                                widget.playerWrapper.setAudioTrack(t);
                                setState(() {});
                              },
                            );
                          }),

                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.glassBorder, height: 1),
                        const SizedBox(height: 16),

                        // Subtitle Tracks
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SUBTITLES', style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
                            InkWell(
                              onTap: _pickSubtitle,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.add, size: 13, color: AppTheme.accent),
                                    const SizedBox(width: 4),
                                    Text('Add .srt/.ass', style: AppTheme.caption.copyWith(color: AppTheme.accent)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subtitle Off Option
                        _trackTile(
                          title: 'Off',
                          isSelected: currentSub == SubtitleTrack.no(),
                          onTap: () {
                            widget.playerWrapper.setSubtitleTrack(SubtitleTrack.no());
                            setState(() {});
                          },
                        ),

                        // Subtitle Track List
                        ...tracks.subtitle.map((s) {
                          final isSelected = s.id == currentSub.id;
                          final label = (s.title?.isNotEmpty ?? false)
                              ? s.title!
                              : (s.language?.isNotEmpty ?? false ? s.language! : 'Subtitle ${s.id}');
                          return _trackTile(
                            title: label,
                            isSelected: isSelected,
                            onTap: () {
                              widget.playerWrapper.setSubtitleTrack(s);
                              setState(() {});
                            },
                          );
                        }),

                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.glassBorder, height: 1),
                        const SizedBox(height: 16),

                        // Subtitle Delay
                        Text('SUBTITLE DELAY', style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDelay(widget.playerWrapper.subtitleDelay),
                              style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, color: AppTheme.accent),
                            ),
                            Row(
                              children: [
                                _delayButton('-0.5s', () {
                                  widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: -500));
                                  setState(() {});
                                }),
                                const SizedBox(width: 6),
                                _delayButton('-0.1s', () {
                                  widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: -100));
                                  setState(() {});
                                }),
                                const SizedBox(width: 6),
                                _delayButton('Reset', () {
                                  widget.playerWrapper.subtitleDelay = Duration.zero;
                                  setState(() {});
                                }),
                                const SizedBox(width: 6),
                                _delayButton('+0.1s', () {
                                  widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: 100));
                                  setState(() {});
                                }),
                                const SizedBox(width: 6),
                                _delayButton('+0.5s', () {
                                  widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: 500));
                                  setState(() {});
                                }),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trackTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark, size: 16, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _delayButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textPrimary)),
      ),
    );
  }
}
