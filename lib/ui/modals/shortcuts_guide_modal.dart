import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class ShortcutsGuideModal extends StatelessWidget {
  const ShortcutsGuideModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => const ShortcutsGuideModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          fillColor: AppTheme.surface.withValues(alpha: 0.92),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.keyboard, size: 20, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text('Shortcuts & Gestures',
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
                        _group('PLAYBACK', [
                          _row('Space', 'Play / Pause'),
                          _row('S', 'Stop playback'),
                          _row('Left / Right Arrow', 'Seek ±5 seconds'),
                          _row('Shift + Left / Right', 'Seek ±30 seconds'),
                          _row('[  /  ]', 'Decrease / Increase Speed'),
                          _row('P  /  N', 'Previous / Next track'),
                        ]),
                        const SizedBox(height: 16),

                        _group('AUDIO & VOLUME', [
                          _row('Up / Down Arrow', 'Volume ±5% (up to 150%)'),
                          _row('M', 'Mute / Unmute'),
                          _row('Mouse Scroll Wheel', 'Smooth volume adjustment'),
                        ]),
                        const SizedBox(height: 16),

                        _group('VIEW & WINDOW', [
                          _row('F  /  Double Click', 'Toggle Fullscreen'),
                          _row('Escape', 'Exit Fullscreen'),
                          _row('Ctrl + L', 'Toggle Playlist Drawer'),
                          _row('Ctrl + I', 'Media & Codec Information'),
                          _row('Shift + S', 'Capture Snapshot (Screenshot)'),
                        ]),
                        const SizedBox(height: 16),

                        _group('FILE MANAGEMENT', [
                          _row('Ctrl + O', 'Open Video File'),
                          _row('Ctrl + N', 'Open Network Stream (URL)'),
                          _row('Drag & Drop', 'Drop video file or folder to play'),
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
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600, color: AppTheme.accent)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _row(String keyText, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Text(keyText,
                style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(desc,
                textAlign: TextAlign.end,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
