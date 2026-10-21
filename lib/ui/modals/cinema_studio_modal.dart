import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import '../../player/player_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/frosted_glass.dart';

class CinemaStudioModal extends StatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const CinemaStudioModal({super.key, required this.playerWrapper});

  static Future<void> show(BuildContext context, AuraPlayerWrapper wrapper) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => CinemaStudioModal(playerWrapper: wrapper),
    );
  }

  @override
  State<CinemaStudioModal> createState() => _CinemaStudioModalState();
}

class _CinemaStudioModalState extends State<CinemaStudioModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDelay(Duration d) {
    final ms = d.inMilliseconds;
    if (ms == 0) return '0 ms';
    final sign = ms > 0 ? '+' : '';
    return '$sign$ms ms';
  }

  String _formatTimestamp(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.playerWrapper.player;
    final rate = player.state.rate;
    final volume = player.state.volume;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FrostedGlass(
          borderRadius: 24,
          padding: EdgeInsets.zero,
          fillColor: const Color(0xFF0C0E14).withValues(alpha: 0.94),
          borderColor: AppTheme.glassBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Studio Header & Title
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.glassBorder, width: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: AppTheme.auraGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.slider_horizontal_3, size: 17, color: Color(0xFF04131F)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'CINEMA STUDIO PRO',
                                    style: AppTheme.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 0.6),
                                    ),
                                    child: Text(
                                      'VLC POWER ENGINE',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accent,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Precision Audio, Subtitles, Geometry & Color Grading',
                                style: AppTheme.caption.copyWith(fontSize: 10.5, color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 2. Tab Bar Selector
                Container(
                  color: AppTheme.surfaceSecondary.withValues(alpha: 0.5),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.accent,
                    indicatorWeight: 2.5,
                    labelColor: AppTheme.accent,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                    tabs: const [
                      Tab(icon: Icon(CupertinoIcons.gauge, size: 15), text: 'Playback'),
                      Tab(icon: Icon(CupertinoIcons.speaker_2_fill, size: 15), text: 'Audio Master'),
                      Tab(icon: Icon(CupertinoIcons.captions_bubble_fill, size: 15), text: 'Subtitles'),
                      Tab(icon: Icon(CupertinoIcons.sparkles, size: 15), text: 'Video & Color'),
                    ],
                  ),
                ),

                // 3. Tab Contents
                Flexible(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlaybackTab(rate),
                      _buildAudioTab(volume),
                      _buildSubtitlesTab(),
                      _buildVideoTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: PLAYBACK & PRECISION ---
  Widget _buildPlaybackTab(double currentRate) {
    final wrapper = widget.playerWrapper;
    final sleepTarget = wrapper.sleepTimerTarget;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playback Speed Slider & Presets
          _sectionHeader('PLAYBACK SPEED RATE', '${currentRate.toStringAsFixed(2)}x'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: AppTheme.accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppTheme.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: currentRate.clamp(0.25, 4.0),
              min: 0.25,
              max: 4.0,
              onChanged: (v) {
                wrapper.setRate(v);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0].map((s) {
              final isSel = (currentRate - s).abs() < 0.05;
              return InkWell(
                onTap: () {
                  wrapper.setRate(s);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.accent : AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSel ? Colors.transparent : AppTheme.glassBorder),
                  ),
                  child: Text(
                    '${s}x',
                    style: AppTheme.caption.copyWith(
                      color: isSel ? const Color(0xFF04131F) : Colors.white70,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 20),

          // A-B Loop Repeat
          _sectionHeader('A-B REPEAT LOOP', 'VLC Precision Loop'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Point A: ${_formatTimestamp(wrapper.loopA)}   →   Point B: ${_formatTimestamp(wrapper.loopB)}',
                      style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      wrapper.loopA != null && wrapper.loopB != null
                          ? 'Looping between A and B'
                          : 'Set Start (A) and End (B) to loop any scene',
                      style: AppTheme.caption.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _smallActionButton('Set A', () {
                      wrapper.setLoopA();
                      setState(() {});
                    }),
                    const SizedBox(width: 6),
                    _smallActionButton('Set B', () {
                      wrapper.setLoopB();
                      setState(() {});
                    }),
                    if (wrapper.loopA != null || wrapper.loopB != null) ...[
                      const SizedBox(width: 6),
                      _smallActionButton('Clear', () {
                        wrapper.clearLoop();
                        setState(() {});
                      }, isDanger: true),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 20),

          // Frame Step & Sleep Timer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('FRAME BY FRAME', 'Exact 1-frame step'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _smallActionButton('◀ Frame', () => wrapper.stepFrameBackward()),
                        const SizedBox(width: 8),
                        _smallActionButton('Frame ▶', () => wrapper.stepFrameForward()),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('SLEEP TIMER', sleepTarget != null ? 'Active' : 'Off'),
                    const SizedBox(height: 10),
                    PopupMenuButton<int>(
                      tooltip: 'Set Sleep Timer',
                      color: const Color(0xFF14141B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      onSelected: (mins) {
                        if (mins == 0) {
                          wrapper.setSleepTimer(null);
                        } else {
                          wrapper.setSleepTimer(Duration(minutes: mins));
                        }
                        setState(() {});
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 0, child: Text('Turn Off Sleep Timer')),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(value: 15, child: Text('15 Minutes')),
                        const PopupMenuItem(value: 30, child: Text('30 Minutes')),
                        const PopupMenuItem(value: 45, child: Text('45 Minutes')),
                        const PopupMenuItem(value: 60, child: Text('1 Hour')),
                        const PopupMenuItem(value: 90, child: Text('1.5 Hours')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sleepTarget != null ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sleepTarget != null ? AppTheme.accent : AppTheme.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.moon_zzz_fill, size: 14, color: sleepTarget != null ? AppTheme.accent : Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              sleepTarget != null
                                  ? '${sleepTarget.difference(DateTime.now()).inMinutes}m left'
                                  : 'Set Timer...',
                              style: AppTheme.caption.copyWith(
                                color: sleepTarget != null ? AppTheme.accent : Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: AUDIO MASTER ---
  Widget _buildAudioTab(double volume) {
    final player = widget.playerWrapper.player;
    final tracks = player.state.tracks.audio;
    final currentAudio = player.state.track.audio;
    final wrapper = widget.playerWrapper;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume Boost Slider up to 200%
          _sectionHeader(
            'MASTER VOLUME & BOOST',
            '${volume.toInt()}% ${volume > 100 ? '(VLC Boost Active)' : ''}',
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              activeTrackColor: volume > 100 ? const Color(0xFFF59E0B) : AppTheme.accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: volume > 100 ? const Color(0xFFFBBF24) : AppTheme.accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: volume.clamp(0.0, 200.0),
              min: 0.0,
              max: 200.0,
              onChanged: (v) {
                wrapper.setVolume(v);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // Audio Sync Delay
          _sectionHeader('AUDIO SYNC DELAY (A/V DESYNC FIX)', _formatDelay(wrapper.audioDelay)),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallActionButton('-50ms', () {
                wrapper.adjustAudioDelay(const Duration(milliseconds: -50));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('-10ms', () {
                wrapper.adjustAudioDelay(const Duration(milliseconds: -10));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('Reset (0ms)', () {
                wrapper.resetAudioDelay();
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('+10ms', () {
                wrapper.adjustAudioDelay(const Duration(milliseconds: 10));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('+50ms', () {
                wrapper.adjustAudioDelay(const Duration(milliseconds: 50));
                setState(() {});
              }),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // Night Mode (Dialogue Clarity & Dynamic Range Compression)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: wrapper.isNightMode ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.glassBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.moon_stars_fill,
                            size: 14,
                            color: wrapper.isNightMode ? AppTheme.accent : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NIGHT MODE (DIALOGUE CLARITY & DRC)',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: wrapper.isNightMode ? AppTheme.accent : Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Boosts quiet dialogues & softens loud explosions for night viewing without disturbing others.',
                        style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                CupertinoSwitch(
                  value: wrapper.isNightMode,
                  activeTrackColor: AppTheme.accent,
                  onChanged: (val) {
                    wrapper.toggleNightMode();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // 10-Band Studio Equalizer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('10-BAND STUDIO EQUALIZER', wrapper.currentEqPreset),
              if (wrapper.currentEqPreset != 'Flat')
                GestureDetector(
                  onTap: () {
                    wrapper.resetEq();
                    setState(() {});
                  },
                  child: Text(
                    'Reset EQ',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // EQ Preset Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AuraPlayerWrapper.eqPresets.keys.map((preset) {
              final isSel = wrapper.currentEqPreset == preset;
              return InkWell(
                onTap: () {
                  wrapper.setEqPreset(preset);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSel ? AppTheme.accent : AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSel ? Colors.transparent : AppTheme.glassBorder),
                  ),
                  child: Text(
                    preset,
                    style: AppTheme.caption.copyWith(
                      color: isSel ? const Color(0xFF04131F) : Colors.white70,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 10 Band Vertical Sliders Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (idx) {
                final bandLabel = AuraPlayerWrapper.eqBands[idx];
                final gain = wrapper.eqGains[idx];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
                      style: AppTheme.caption.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: gain != 0 ? AppTheme.accent : Colors.white38,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      width: 24,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2.5,
                            activeTrackColor: AppTheme.accent,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: gain != 0 ? AppTheme.accent : Colors.white60,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                          ),
                          child: Slider(
                            value: gain,
                            min: -12.0,
                            max: 12.0,
                            onChanged: (v) {
                              wrapper.setEqBand(idx, v);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      bandLabel,
                      style: AppTheme.caption.copyWith(fontSize: 8.5, color: Colors.white60),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // Audio Tracks
          _sectionHeader('SELECT AUDIO TRACK', '${tracks.length} tracks detected'),
          const SizedBox(height: 10),
          if (tracks.isEmpty)
            Text('No alternate audio tracks in current stream', style: AppTheme.caption)
          else
            ...tracks.map((t) {
              final isSel = t.id == currentAudio.id;
              final label = (t.title?.isNotEmpty ?? false)
                  ? t.title!
                  : (t.language?.isNotEmpty ?? false ? t.language! : 'Track ${t.id}');
              return _trackRow(
                title: label,
                isSelected: isSel,
                onTap: () {
                  wrapper.setAudioTrack(t);
                  setState(() {});
                },
              );
            }),
        ],
      ),
    );
  }

  // --- TAB 3: SUBTITLE STUDIO ---
  Widget _buildSubtitlesTab() {
    final player = widget.playerWrapper.player;
    final tracks = player.state.tracks.subtitle;
    final currentSub = player.state.track.subtitle;
    final wrapper = widget.playerWrapper;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle Sync Delay
          _sectionHeader('SUBTITLE SYNC DELAY', _formatDelay(wrapper.subtitleDelay)),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallActionButton('-500ms', () {
                wrapper.adjustSubtitleDelay(const Duration(milliseconds: -500));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('-100ms', () {
                wrapper.adjustSubtitleDelay(const Duration(milliseconds: -100));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('Reset', () {
                wrapper.resetSubtitleDelay();
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('+100ms', () {
                wrapper.adjustSubtitleDelay(const Duration(milliseconds: 100));
                setState(() {});
              }),
              const SizedBox(width: 6),
              _smallActionButton('+500ms', () {
                wrapper.adjustSubtitleDelay(const Duration(milliseconds: 500));
                setState(() {});
              }),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // External Subtitle Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('SUBTITLE TRACKS', ''),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['srt', 'ass', 'vtt', 'sub'],
                  );
                  if (res != null && res.files.single.path != null) {
                    await wrapper.loadExternalSubtitle(res.files.single.path!);
                    setState(() {});
                  }
                },
                icon: const Icon(CupertinoIcons.plus, size: 13),
                label: const Text('Add .SRT / .ASS File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF04131F),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtitle Off
          _trackRow(
            title: 'Subtitles Off (Disabled)',
            isSelected: currentSub == SubtitleTrack.no(),
            onTap: () {
              wrapper.setSubtitleTrack(SubtitleTrack.no());
              setState(() {});
            },
          ),

          ...tracks.map((s) {
            final isSel = s.id == currentSub.id;
            final label = (s.title?.isNotEmpty ?? false)
                ? s.title!
                : (s.language?.isNotEmpty ?? false ? s.language! : 'Subtitle ${s.id}');
            return _trackRow(
              title: label,
              isSelected: isSel,
              onTap: () {
                wrapper.setSubtitleTrack(s);
                setState(() {});
              },
            );
          }),
        ],
      ),
    );
  }

  // --- TAB 4: VIDEO COLOR & GEOMETRY ---
  Widget _buildVideoTab() {
    final wrapper = widget.playerWrapper;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aspect Ratio Overrides
          _sectionHeader('ASPECT RATIO OVERRIDE', wrapper.currentAspectRatio ?? 'Default'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ratioPill('default', 'Auto / Source', wrapper.currentAspectRatio == null || wrapper.currentAspectRatio == 'default'),
              _ratioPill('16:9', '16:9 Widescreen', wrapper.currentAspectRatio == '16:9'),
              _ratioPill('21:9', '21:9 CinemaScope', wrapper.currentAspectRatio == '21:9'),
              _ratioPill('4:3', '4:3 Classic TV', wrapper.currentAspectRatio == '4:3'),
              _ratioPill('1.85:1', '1.85:1 Academy', wrapper.currentAspectRatio == '1.85:1'),
            ],
          ),

          const SizedBox(height: 22),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // Real-time Color Adjustments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('REAL-TIME COLOR GRADING', 'Direct GPU Shaders'),
              TextButton(
                onPressed: () {
                  wrapper.resetVideoAdjustments();
                  setState(() {});
                },
                child: const Text('Reset All', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _colorSlider('Brightness', wrapper.brightness, (v) {
            wrapper.setBrightness(v);
            setState(() {});
          }),
          _colorSlider('Contrast', wrapper.contrast, (v) {
            wrapper.setContrast(v);
            setState(() {});
          }),
          _colorSlider('Saturation', wrapper.saturation, (v) {
            wrapper.setSaturation(v);
            setState(() {});
          }),
          _colorSlider('Gamma', wrapper.gamma, (v) {
            wrapper.setGamma(v);
            setState(() {});
          }),

          const SizedBox(height: 18),
          const Divider(color: AppTheme.glassBorder, height: 1),
          const SizedBox(height: 16),

          // Hardware Engine Stats & Snapshot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HARDWARE ACCELERATION', style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Direct3D11 Native (GPU Decoding) • 60 FPS HDR', style: AppTheme.caption.copyWith(color: AppTheme.accent, fontSize: 11)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await wrapper.takeSnapshot();
                  if (mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Frame saved to Pictures: ${path.split(RegExp(r"[/\\]")).last}')),
                    );
                  }
                },
                icon: const Icon(CupertinoIcons.camera_fill, size: 14),
                label: const Text('Capture Snapshot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.glassBorderHover),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---
  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 10.5,
            color: AppTheme.accent,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 11),
          ),
      ],
    );
  }

  Widget _smallActionButton(String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0x33EF4444) : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDanger ? const Color(0xFFEF4444) : AppTheme.glassBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: isDanger ? const Color(0xFFEF4444) : Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _trackRow({required String title, required bool isSelected, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.surfaceSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: isSelected ? AppTheme.accent : Colors.white,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratioPill(String ratioKey, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        widget.playerWrapper.setAspectRatio(ratioKey);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.transparent : AppTheme.glassBorder),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            color: isSelected ? const Color(0xFF04131F) : Colors.white70,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _colorSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(label, style: AppTheme.caption.copyWith(color: Colors.white70)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                activeTrackColor: AppTheme.accent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value.clamp(-100.0, 100.0),
                min: -100.0,
                max: 100.0,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toInt().toString(),
              textAlign: TextAlign.right,
              style: AppTheme.caption.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
