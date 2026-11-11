import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import '../../player/player_controller.dart';
import '../../player/track_formatters.dart';
import '../../state/player_provider.dart';
import '../../theme/app_theme.dart';

class UnifiedInspectorDrawer extends ConsumerStatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const UnifiedInspectorDrawer({
    super.key,
    required this.playerWrapper,
  });

  @override
  ConsumerState<UnifiedInspectorDrawer> createState() => _UnifiedInspectorDrawerState();
}

class _UnifiedInspectorDrawerState extends ConsumerState<UnifiedInspectorDrawer> {
  // Video sliders state
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _gamma;

  bool get _isDark => ref.watch(themeModeProvider) == ThemeMode.dark;
  Color get _glassBorder => _isDark ? const Color(0x40FFFFFF) : const Color(0x30000000);
  Color get _textPrimary => _isDark ? Colors.white : AppTheme.lightTextPrimary;
  Color get _textSecondary => _isDark ? Colors.white70 : AppTheme.lightTextSecondary;
  Color get _cardBg => _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.55);
  Color get _accentColor => _isDark ? AppTheme.accentCyan : const Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _brightness = widget.playerWrapper.brightness;
    _contrast = widget.playerWrapper.contrast;
    _saturation = widget.playerWrapper.saturation;
    _gamma = widget.playerWrapper.gamma;
  }

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0 ms';
    final sign = ms > 0 ? '+' : '';
    return '$sign$ms ms';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final windowState = ref.watch(windowControlsProvider);
    final windowNotifier = ref.read(windowControlsProvider.notifier);
    final activeTab = windowState.inspectorTab;
    final isDark = _isDark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.14),
                      const Color(0xFF070A12).withValues(alpha: 0.40),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.45),
                    ],
            ),
            border: Border(
              left: BorderSide(
                color: isDark ? const Color(0x45FFFFFF) : const Color(0x30000000),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drawer Header with Back Button
              _buildHeader(context, windowNotifier),

              // 2. Segmented Navigation Bar (Video, Audio, Subs, Info)
              _buildSegmentTabs(activeTab, windowNotifier),

              // 3. Tab Contents
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: _buildActiveTabContent(activeTab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WindowControlsNotifier windowNotifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Minimal Back Arrow Button (Icon only)
          Tooltip(
            message: 'Close Inspector',
            child: InkWell(
              onTap: () => windowNotifier.closeInspector(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _glassBorder,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: _accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.auraGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: Color(0xFF04131F),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STUDIO INSPECTOR',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _textPrimary,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  'Real-Time Calibration',
                  style: AppTheme.caption.copyWith(
                    fontSize: 9.5,
                    color: _textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close Inspector (I)',
            icon: Icon(Icons.close_rounded, size: 20, color: _textSecondary),
            hoverColor: _isDark ? Colors.white12 : Colors.black12,
            onPressed: () => windowNotifier.closeInspector(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs(int activeTab, WindowControlsNotifier windowNotifier) {
    const tabs = [
      {'title': 'Video', 'icon': Icons.movie_rounded},
      {'title': 'Audio', 'icon': Icons.volume_up_rounded},
      {'title': 'Subtitles', 'icon': Icons.subtitles_rounded},
      {'title': 'Info', 'icon': Icons.info_rounded},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _glassBorder, width: 0.8),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _glassBorder),
        ),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = activeTab == idx;
            final item = tabs[idx];
            return Expanded(
              child: InkWell(
                onTap: () => windowNotifier.openInspector(tab: idx),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isDark
                            ? AppTheme.accent.withValues(alpha: 0.22)
                            : AppTheme.accentDark.withValues(alpha: 0.16))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: _isDark
                                ? AppTheme.accent.withValues(alpha: 0.7)
                                : AppTheme.accentDark.withValues(alpha: 0.6),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 13,
                        color: isSelected ? _accentColor : _textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['title'] as String,
                        style: AppTheme.caption.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (_isDark ? Colors.white : AppTheme.accentDark)
                              : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(int activeTab) {
    switch (activeTab) {
      case 0:
        return _buildVideoTab();
      case 1:
        return _buildAudioTab();
      case 2:
        return _buildSubtitlesTab();
      case 3:
        return _buildMediaInfoTab();
      default:
        return _buildVideoTab();
    }
  }

  // ==========================================
  // TAB 0: VIDEO ADJUSTMENTS
  // ==========================================
  Widget _buildVideoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('COLOR CALIBRATION'),
        const SizedBox(height: 10),

        _sliderRow('Brightness', _brightness, -100, 100, (v) {
          setState(() => _brightness = v);
          widget.playerWrapper.setBrightness(v);
        }),
        _sliderRow('Contrast', _contrast, -100, 100, (v) {
          setState(() => _contrast = v);
          widget.playerWrapper.setContrast(v);
        }),
        _sliderRow('Saturation', _saturation, -100, 100, (v) {
          setState(() => _saturation = v);
          widget.playerWrapper.setSaturation(v);
        }),
        _sliderRow('Gamma', _gamma, -100, 100, (v) {
          setState(() => _gamma = v);
          widget.playerWrapper.setGamma(v);
        }),

        const SizedBox(height: 14),
        _sectionTitle('ASPECT RATIO'),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ratioChip('Default (Auto)', null),
            _ratioChip('16:9', '16:9'),
            _ratioChip('4:3', '4:3'),
            _ratioChip('21:9', '21:9'),
          ],
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: _cardBg,
            ),
            icon: Icon(Icons.replay_rounded, size: 14, color: _accentColor),
            label: Text('Reset Video Adjustments', style: TextStyle(color: _textPrimary, fontSize: 12)),
            onPressed: () {
              setState(() {
                _brightness = 0.0;
                _contrast = 0.0;
                _saturation = 0.0;
                _gamma = 0.0;
              });
              widget.playerWrapper.resetVideoAdjustments();
              widget.playerWrapper.setAspectRatio(null);
            },
          ),
        ),
      ],
    );
  }

  Widget _ratioChip(String label, String? ratioVal) {
    final isSelected = widget.playerWrapper.currentAspectRatio == ratioVal;
    return InkWell(
      onTap: () {
        widget.playerWrapper.setAspectRatio(ratioVal);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDark ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.accentDark.withValues(alpha: 0.16))
              : _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : _glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? (_isDark ? Colors.white : AppTheme.accentDark) : _textSecondary,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: AUDIO & EQUALIZER
  // ==========================================
  Widget _buildAudioTab() {
    final player = widget.playerWrapper.player;
    final volume = player.state.volume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('VOLUME BOOST & DELAY'),
        const SizedBox(height: 10),

        // Volume Boost Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Master Volume', style: AppTheme.bodySmall.copyWith(color: _textSecondary)),
            Text(
              '${volume.toInt()}%',
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: volume > 100 ? Colors.orangeAccent : _accentColor,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: volume > 100 ? Colors.orangeAccent : _accentColor,
            inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
            thumbColor: _isDark ? Colors.white : AppTheme.accentDark,
          ),
          child: Slider(
            value: volume.clamp(0.0, 150.0),
            min: 0.0,
            max: 150.0,
            onChanged: (v) {
              widget.playerWrapper.setVolume(v);
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 8),

        // Audio Delay Sync
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Audio Delay Sync', style: AppTheme.bodySmall.copyWith(color: _textSecondary)),
            Text(
              _formatDelay(widget.playerWrapper.audioDelay),
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.playerWrapper.audioDelay != Duration.zero ? _accentColor : _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _delayButton('-50ms', () {
              widget.playerWrapper.adjustAudioDelay(const Duration(milliseconds: -50));
              setState(() {});
            }),
            const SizedBox(width: 6),
            _delayButton('+50ms', () {
              widget.playerWrapper.adjustAudioDelay(const Duration(milliseconds: 50));
              setState(() {});
            }),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: _cardBg,
                ),
                onPressed: () {
                  widget.playerWrapper.resetAudioDelay();
                  setState(() {});
                },
                child: Text('Reset Sync', style: TextStyle(color: _textSecondary, fontSize: 11)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Night Mode Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.playerWrapper.isNightMode
                ? (_isDark ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.accentDark.withValues(alpha: 0.12))
                : _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.playerWrapper.isNightMode
                  ? (_isDark ? AppTheme.accent.withValues(alpha: 0.6) : AppTheme.accentDark.withValues(alpha: 0.6))
                  : _glassBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.nightlight_round,
                size: 16,
                color: widget.playerWrapper.isNightMode ? _accentColor : _textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Night Mode (Dialogue Clarity)',
                      style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700, color: _textPrimary),
                    ),
                    Text(
                      'Dynamic Range Compression for clear speech',
                      style: AppTheme.caption.copyWith(fontSize: 9.5, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: widget.playerWrapper.isNightMode,
                activeTrackColor: _accentColor,
                onChanged: (val) {
                  widget.playerWrapper.toggleNightMode();
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        _sectionTitle('10-BAND EQUALIZER'),
        const SizedBox(height: 8),

        // Presets Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AuraPlayerWrapper.eqPresets.keys.map((preset) {
            final isCur = widget.playerWrapper.currentEqPreset == preset;
            return InkWell(
              onTap: () {
                widget.playerWrapper.setEqPreset(preset);
                setState(() {});
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isCur
                      ? (_isDark ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.accentDark.withValues(alpha: 0.16))
                      : _cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCur ? _accentColor : _glassBorder,
                  ),
                ),
                child: Text(
                  preset,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                    color: isCur ? (_isDark ? Colors.white : AppTheme.accentDark) : _textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Equalizer bands list
        ...List.generate(AuraPlayerWrapper.eqBands.length, (i) {
          final bandName = AuraPlayerWrapper.eqBands[i];
          final gain = widget.playerWrapper.eqGains[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    bandName,
                    style: AppTheme.caption.copyWith(fontSize: 10.5, color: _textSecondary),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      activeTrackColor: _accentColor,
                      inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
                      thumbColor: _isDark ? Colors.white : AppTheme.accentDark,
                    ),
                    child: Slider(
                      value: gain.clamp(-12.0, 12.0),
                      min: -12.0,
                      max: 12.0,
                      onChanged: (v) {
                        widget.playerWrapper.setEqBand(i, v);
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)}dB',
                    textAlign: TextAlign.right,
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: gain.abs() > 0.05 ? _accentColor : _textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: _cardBg,
            ),
            icon: Icon(Icons.replay_rounded, size: 14, color: _accentColor),
            label: Text('Reset Equalizer to Flat', style: TextStyle(color: _textPrimary, fontSize: 12)),
            onPressed: () {
              widget.playerWrapper.resetEq();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: SUBTITLES & STYLING
  // ==========================================
  Widget _buildSubtitlesTab() {
    final player = widget.playerWrapper.player;
    final tracks = player.state.tracks.subtitle;
    final currentSub = player.state.track.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('SUBTITLE TRACKS'),
        const SizedBox(height: 8),

        // Subtitle selector dropdown container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SubtitleTrack>(
              isExpanded: true,
              dropdownColor: _isDark ? const Color(0xFF141722) : Colors.white,
              value: tracks.contains(currentSub) ? currentSub : (tracks.isNotEmpty ? tracks.first : null),
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _textSecondary),
              items: tracks.map((track) {
                final isOff = track.id == 'no' || track.id == 'auto';
                final label = isOff ? 'Disabled / Off' : TrackFormatters.formatSubtitleTrack(track);
                return DropdownMenuItem(
                  value: track,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: track == currentSub ? FontWeight.w700 : FontWeight.w400,
                      color: track == currentSub ? _accentColor : _textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (track) {
                if (track != null) {
                  widget.playerWrapper.setSubtitleTrack(track);
                  setState(() {});
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Load external subtitle button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 9),
              backgroundColor: _cardBg,
            ),
            icon: Icon(Icons.create_new_folder_rounded, size: 15, color: _accentColor),
            label: Text('Add External Subtitle (.srt, .vtt, .ass)...',
                style: TextStyle(color: _textPrimary, fontSize: 11.5)),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['srt', 'vtt', 'ass', 'sub'],
              );
              if (result != null && result.files.single.path != null) {
                await widget.playerWrapper.loadExternalSubtitle(result.files.single.path!);
                setState(() {});
              }
            },
          ),
        ),

        const SizedBox(height: 18),
        _sectionTitle('SUBTITLE SYNC DELAY'),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Timing Offset', style: AppTheme.bodySmall.copyWith(color: _textSecondary)),
            Text(
              _formatDelay(widget.playerWrapper.subtitleDelay),
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.playerWrapper.subtitleDelay != Duration.zero ? _accentColor : _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _delayButton('-50ms', () {
              widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: -50));
              setState(() {});
            }),
            const SizedBox(width: 6),
            _delayButton('+50ms', () {
              widget.playerWrapper.adjustSubtitleDelay(const Duration(milliseconds: 50));
              setState(() {});
            }),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: _cardBg,
                ),
                onPressed: () {
                  widget.playerWrapper.resetSubtitleDelay();
                  setState(() {});
                },
                child: Text('Reset Sync', style: TextStyle(color: _textSecondary, fontSize: 11)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        _sectionTitle('SUBTITLE APPEARANCE'),
        const SizedBox(height: 10),

        // Font size slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Font Size', style: AppTheme.bodySmall.copyWith(color: _textSecondary)),
            Text('${widget.playerWrapper.subFontSize.toInt()} px',
                style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700, color: _accentColor)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: _accentColor,
            inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
            thumbColor: _isDark ? Colors.white : AppTheme.accentDark,
          ),
          child: Slider(
            value: widget.playerWrapper.subFontSize.clamp(20.0, 72.0),
            min: 20.0,
            max: 72.0,
            onChanged: (v) {
              widget.playerWrapper.setSubtitleFontSize(v);
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 8),

        // Color chips
        Text('Color Palette', style: AppTheme.caption.copyWith(color: _textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            _colorChip(const Color(0xFFFFFFFF), 'White'),
            const SizedBox(width: 8),
            _colorChip(const Color(0xFFFFF176), 'Yellow'),
            const SizedBox(width: 8),
            _colorChip(const Color(0xFF00E5FF), 'Cyan'),
            const SizedBox(width: 8),
            _colorChip(const Color(0xFF69F0AE), 'Green'),
          ],
        ),

        const SizedBox(height: 12),

        // Background mode
        Text('Background Mode', style: AppTheme.caption.copyWith(color: _textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            _bgModeChip('none', 'Transparent'),
            const SizedBox(width: 6),
            _bgModeChip('glass', 'Frosted Glass'),
            const SizedBox(width: 6),
            _bgModeChip('opaque', 'Solid Black'),
          ],
        ),

        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: _cardBg,
            ),
            icon: Icon(Icons.replay_rounded, size: 14, color: _accentColor),
            label: Text('Reset Subtitle Styling', style: TextStyle(color: _textPrimary, fontSize: 12)),
            onPressed: () {
              widget.playerWrapper.resetSubtitleAppearance();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _colorChip(Color color, String label) {
    final isSelected = widget.playerWrapper.subColor.toARGB32() == color.toARGB32();
    return InkWell(
      onTap: () {
        widget.playerWrapper.setSubtitleColor(color);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _accentColor : _glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10.5, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _bgModeChip(String mode, String label) {
    final isSelected = widget.playerWrapper.subBgMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.playerWrapper.setSubtitleBgMode(mode);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (_isDark ? AppTheme.accent.withValues(alpha: 0.25) : AppTheme.accentDark.withValues(alpha: 0.16))
                : _cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? _accentColor : _glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? (_isDark ? Colors.white : AppTheme.accentDark) : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: MEDIA INFO & CODECS
  // ==========================================
  Widget _buildMediaInfoTab() {
    final player = widget.playerWrapper.player;
    final state = player.state;
    final tracks = state.tracks;
    final path = widget.playerWrapper.currentFilePath ?? 'None';
    final title = widget.playerWrapper.currentTitle ?? 'No media loaded';
    final duration = state.duration;

    final width = state.width ?? 0;
    final height = state.height ?? 0;
    final is4K = width >= 3840 || height >= 2160;
    final is1080p = width >= 1920 || height >= 1080;
    final qualityBadge = is4K ? '4K UHD' : (is1080p ? '1080p FHD' : (width > 0 ? '${height}p' : 'Unknown'));

    final audioInfo = tracks.audio.map((a) => TrackFormatters.formatAudioTrack(a)).join('\n');
    final subInfo = tracks.subtitle.map((s) => TrackFormatters.formatSubtitleTrack(s)).join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quality Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentColor.withValues(alpha: 0.20),
                _accentColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: _accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct3D11 Hardware Accelerated',
                      style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700, color: _textPrimary),
                    ),
                    Text(
                      'libmpv Native Pipeline Active ($qualityBadge)',
                      style: AppTheme.caption.copyWith(fontSize: 10, color: _accentColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _sectionTitle('GENERAL SPECIFICATIONS'),
        const SizedBox(height: 8),

        _infoRow('Title', title),
        _infoRow('Duration', _formatDuration(duration)),
        _infoRow('File Location', path, isSelectable: true),
        _infoRow('Engine', 'libmpv / media_kit Direct3D11'),

        const SizedBox(height: 16),
        _sectionTitle('VIDEO STREAM'),
        const SizedBox(height: 8),

        _infoRow('Resolution', width > 0 ? '${width}x$height ($qualityBadge)' : 'Detecting...'),
        _infoRow('Aspect Ratio', widget.playerWrapper.currentAspectRatio ?? 'Default (Auto)'),
        _infoRow('Hardware Decoder', 'D3D11VA / auto-safe'),

        const SizedBox(height: 16),
        _sectionTitle('AUDIO STREAMS'),
        const SizedBox(height: 8),

        _infoRow('Current Audio', state.track.audio.title ?? state.track.audio.language ?? 'Default'),
        _infoRow('Total Tracks', '${tracks.audio.length} available'),
        if (audioInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(audioInfo, style: TextStyle(fontSize: 10.5, color: _textSecondary, height: 1.4)),
          ),

        const SizedBox(height: 16),
        _sectionTitle('SUBTITLE STREAMS'),
        const SizedBox(height: 8),

        _infoRow('Current Track', state.track.subtitle.title ?? state.track.subtitle.language ?? 'Off'),
        _infoRow('Total Subtitles', '${tracks.subtitle.length} available'),
        if (subInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(subInfo, style: TextStyle(fontSize: 10.5, color: _textSecondary, height: 1.4)),
          ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _glassBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: _cardBg,
            ),
            icon: Icon(Icons.content_copy_rounded, size: 14, color: _accentColor),
            label: Text('Copy Diagnostics to Clipboard', style: TextStyle(color: _textPrimary, fontSize: 12)),
            onPressed: () {
              final text = '''AuraPlayer Diagnostic Report:
File: $title
Location: $path
Resolution: ${width}x$height ($qualityBadge)
Duration: ${_formatDuration(duration)}
HW Decoder: D3D11VA Active
Audio: ${tracks.audio.length} tracks
Subtitles: ${tracks.subtitle.length} tracks''';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Diagnostics copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _isDark ? const Color(0xFF1E1E28) : const Color(0xFF0F172A),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.caption.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 10.5,
        letterSpacing: 0.9,
        color: _accentColor,
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.caption.copyWith(color: _textSecondary, fontSize: 11)),
              Text(
                '${value.toInt()}',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: value != 0 ? _accentColor : _textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
              activeTrackColor: _accentColor,
              inactiveTrackColor: _isDark ? Colors.white24 : Colors.black12,
              thumbColor: _isDark ? Colors.white : AppTheme.accentDark,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _delayButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _glassBorder),
        ),
        child: Text(label, style: TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: isSelectable
                ? SelectableText(
                    value,
                    style: AppTheme.caption.copyWith(
                      color: _textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    value,
                    style: AppTheme.caption.copyWith(
                      color: _textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
