import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../player/player_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class VideoAdjustmentsModal extends StatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const VideoAdjustmentsModal({super.key, required this.playerWrapper});

  static Future<void> show(BuildContext context, AuraPlayerWrapper wrapper) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => VideoAdjustmentsModal(playerWrapper: wrapper),
    );
  }

  @override
  State<VideoAdjustmentsModal> createState() => _VideoAdjustmentsModalState();
}

class _VideoAdjustmentsModalState extends State<VideoAdjustmentsModal> {
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _gamma;

  @override
  void initState() {
    super.initState();
    _brightness = widget.playerWrapper.brightness;
    _contrast = widget.playerWrapper.contrast;
    _saturation = widget.playerWrapper.saturation;
    _gamma = widget.playerWrapper.gamma;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          fillColor: AppTheme.surface.withValues(alpha: 0.88),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                        const Icon(CupertinoIcons.dial, size: 20, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text('Video Adjustments & Filters',
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

                _sliderRow('Brightness', _brightness, -100, 100, (v) {
                  setState(() => _brightness = v);
                  widget.playerWrapper.setBrightness(v);
                }),
                const SizedBox(height: 12),

                _sliderRow('Contrast', _contrast, -100, 100, (v) {
                  setState(() => _contrast = v);
                  widget.playerWrapper.setContrast(v);
                }),
                const SizedBox(height: 12),

                _sliderRow('Saturation', _saturation, -100, 100, (v) {
                  setState(() => _saturation = v);
                  widget.playerWrapper.setSaturation(v);
                }),
                const SizedBox(height: 12),

                _sliderRow('Gamma', _gamma, -100, 100, (v) {
                  setState(() => _gamma = v);
                  widget.playerWrapper.setGamma(v);
                }),

                const SizedBox(height: 24),
                const Divider(color: AppTheme.glassBorder, height: 1),
                const SizedBox(height: 16),

                // Reset Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _brightness = 0.0;
                          _contrast = 0.0;
                          _saturation = 0.0;
                          _gamma = 0.0;
                        });
                        widget.playerWrapper.resetVideoAdjustments();
                      },
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14),
                      label: const Text('Reset to Defaults'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        textStyle: AppTheme.caption,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodySmall),
            Text(value.toInt().toString(),
                style: AppTheme.caption.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
