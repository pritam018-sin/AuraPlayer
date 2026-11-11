import 'dart:ui';
import 'package:flutter/material.dart';
import '../../player/player_models.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OpenNetworkModal extends ConsumerStatefulWidget {
  const OpenNetworkModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: const OpenNetworkModal(),
      ),
    );
  }

  @override
  ConsumerState<OpenNetworkModal> createState() => _OpenNetworkModalState();
}

class _OpenNetworkModalState extends ConsumerState<OpenNetworkModal> {
  final TextEditingController _urlController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      final text = _urlController.text.trim();
      final valid = text.startsWith('http://') ||
          text.startsWith('https://') ||
          text.startsWith('rtsp://') ||
          text.startsWith('rtmp://') ||
          text.startsWith('mms://');
      if (valid != _isValid) {
        setState(() => _isValid = valid);
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      final title = url.split('/').last.split('?').first;
      final effectiveTitle = title.isEmpty ? 'Network Stream' : title;
      ref.read(playlistProvider.notifier).addItem(
            PlaylistItem(path: url, title: effectiveTitle),
            playImmediately: true,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textPrimary = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.glassBorder : AppTheme.lightGlassBorder;
    final cardBg = isDark
        ? const Color(0xFF0C101A).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.65);
    final fieldBg = isDark
        ? const Color(0xFF131522).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.85);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          blur: 35,
          fillColor: cardBg,
          borderColor: borderCol,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, size: 20, color: AppTheme.accent),
                        const SizedBox(width: 10),
                        Text(
                          'Open Network Stream (URL)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter an HTTP, HTTPS, HLS (.m3u8), or RTSP streaming link:',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _urlController,
                  autofocus: true,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://example.com/live/stream.m3u8',
                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accent),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: textSecondary),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isValid ? _submit : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Play Stream'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF04131F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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
}
