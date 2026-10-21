import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import '../services/thumbnail_service.dart';
import '../settings/storage_service.dart';
import 'player_models.dart';

class AuraPlayerWrapper {
  final StorageService storageService;

  late final Player player;
  late final VideoController videoController;

  String? currentFilePath;
  String? currentTitle;
  Duration subtitleDelay = Duration.zero;
  Duration audioDelay = Duration.zero;
  Duration? loopA;
  Duration? loopB;
  Timer? _sleepTimer;
  DateTime? sleepTimerTarget;

  // Video ready & buffering status notifiers for cinematic loading animations
  final ValueNotifier<bool> isVideoReadyNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isBufferingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> streamErrorNotifier = ValueNotifier<String?>(null);

  // Video Adjustments
  double brightness = 0.0; // -100 to 100
  double contrast = 0.0;   // -100 to 100
  double saturation = 0.0; // -100 to 100
  double gamma = 0.0;      // -100 to 100
  String? currentAspectRatio; // null, "16:9", "4:3", "21:9", "1:1"

  bool get isLiveStream {
    final path = currentFilePath;
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  AuraPlayerWrapper({required this.storageService}) {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'AuraPlayer',
        ready: null,
      ),
    );
    videoController = VideoController(player);

    // Apply resilient network properties for MPV live streaming & hardware decode
    try {
      (player.platform as dynamic)?.setProperty(
        'user-agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      );
      (player.platform as dynamic)?.setProperty(
        'demuxer-lavf-o',
        'protocol_whitelist=file,http,https,tcp,tls,crypto',
      );
      (player.platform as dynamic)?.setProperty('network-timeout', '10');
      (player.platform as dynamic)?.setProperty('hls-bitrate', 'max');
    } catch (_) {}

    // Save playback position periodically (only for offline videos) & enforce A-B loop
    _initPositionSaver();
  }

  void _initPositionSaver() {
    player.stream.width.listen((w) {
      if (w != null && w > 0) {
        isVideoReadyNotifier.value = true;
      }
    });

    player.stream.buffering.listen((buffering) {
      isBufferingNotifier.value = buffering;
    });

    player.stream.error.listen((err) {
      if (err.isNotEmpty) {
        streamErrorNotifier.value = err;
      }
    });

    player.stream.position.listen((pos) {
      if (pos > const Duration(milliseconds: 250)) {
        isVideoReadyNotifier.value = true;
      }

      // Enforce A-B loop repeat
      if (loopA != null && loopB != null && loopB! > loopA!) {
        if (pos >= loopB!) {
          player.seek(loopA!);
          return;
        }
      }

      final path = currentFilePath;
      // Never save live stream position
      if (path != null && !path.startsWith('http://') && !path.startsWith('https://')) {
        if (pos.inSeconds >= 1) {
          ThumbnailService.captureAndSaveFromPlayer(player, path);
        }
        if (pos.inSeconds > 2) {
          storageService.setPosition(path, pos);
        }
      }
    });

    player.stream.completed.listen((completed) {
      final path = currentFilePath;
      if (completed && path != null && !path.startsWith('http://') && !path.startsWith('https://')) {
        // Reset saved position if offline video reached the end
        storageService.setPosition(path, Duration.zero);
      }
    });
  }

  void setLoopA() {
    loopA = player.state.position;
  }

  void setLoopB() {
    loopB = player.state.position;
  }

  void clearLoop() {
    loopA = null;
    loopB = null;
  }

  void stepFrameForward() {
    try {
      (player.platform as dynamic)?.command(['frame-step']);
    } catch (_) {}
  }

  void stepFrameBackward() {
    try {
      (player.platform as dynamic)?.command(['frame-back-step']);
    } catch (_) {}
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      sleepTimerTarget = null;
      return;
    }
    sleepTimerTarget = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      pause();
      sleepTimerTarget = null;
    });
  }

  Future<void> openFile(String path, {String? title}) async {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    currentFilePath = path;
    currentTitle = title ??
        (isNetwork
            ? path.split('/').last.split('?').first
            : path.split(RegExp(r'[/\\]')).last);
    if (currentTitle == null || currentTitle!.isEmpty) {
      currentTitle = isNetwork ? 'Live Stream' : 'Video';
    }

    // Trigger instant loading animation state
    isVideoReadyNotifier.value = false;
    isBufferingNotifier.value = true;
    streamErrorNotifier.value = null;

    // Only resume saved position for offline local files, never for live streams
    final lastPos = isNetwork ? Duration.zero : storageService.getPosition(path);

    await player.open(
      Media(
        path,
        httpHeaders: isNetwork
            ? {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Accept': '*/*',
              }
            : null,
      ),
      play: true,
    );

    // Resume position if greater than 3 seconds (ONLY offline local files)
    if (!isNetwork && lastPos.inSeconds > 3) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (currentFilePath == path) {
          player.seek(lastPos);
        }
      });
    }

    // Add to recents
    storageService.addRecentFile(
      RecentItem(
        path: path,
        title: currentTitle ?? 'Video',
        position: lastPos,
        duration: isNetwork ? Duration.zero : player.state.duration,
        lastPlayed: DateTime.now(),
      ),
    );
  }

  Future<void> openUrl(String url, {String? title}) async {
    await openFile(url, title: title);
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> playOrPause() => player.playOrPause();

  Future<void> stop() async {
    currentFilePath = null;
    currentTitle = null;
    isVideoReadyNotifier.value = false;
    isBufferingNotifier.value = false;
    streamErrorNotifier.value = null;
    await player.stop();
  }

  Future<void> seek(Duration position) => player.seek(position);

  Future<void> seekRelative(Duration delta) async {
    final current = player.state.position;
    final total = player.state.duration;
    var target = current + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    await player.seek(target);
  }

  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(0.0, 200.0);
    await player.setVolume(clamped);
    await storageService.setVolume(clamped);
  }

  Future<void> changeVolumeRelative(double delta) async {
    final current = player.state.volume;
    await setVolume(current + delta);
  }

  Future<void> toggleMute() async {
    final currentVol = player.state.volume;
    if (currentVol > 0) {
      await storageService.setVolume(currentVol);
      await player.setVolume(0);
      await storageService.setMuted(true);
    } else {
      final saved = storageService.getVolume();
      final restore = saved > 0 ? saved : 80.0;
      await player.setVolume(restore);
      await storageService.setMuted(false);
    }
  }

  Future<void> setRate(double rate) async {
    final clamped = rate.clamp(0.25, 4.0);
    await player.setRate(clamped);
    await storageService.setSpeed(clamped);
  }

  Future<void> cycleSpeed() async {
    final current = player.state.rate;
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final next = speeds.firstWhere((s) => s > current + 0.05, orElse: () => speeds.first);
    await setRate(next);
  }

  Future<void> setAudioTrack(AudioTrack track) => player.setAudioTrack(track);

  Future<void> setSubtitleTrack(SubtitleTrack track) => player.setSubtitleTrack(track);

  Future<void> loadExternalSubtitle(String srtOrAssPath) async {
    final customSub = SubtitleTrack.uri(
      srtOrAssPath,
      title: srtOrAssPath.split(RegExp(r'[/\\]')).last,
    );
    await player.setSubtitleTrack(customSub);
  }

  void adjustSubtitleDelay(Duration delta) {
    subtitleDelay += delta;
    try {
      (player.platform as dynamic)?.setProperty(
        'sub-delay',
        (subtitleDelay.inMilliseconds / 1000.0).toString(),
      );
    } catch (_) {}
  }

  void resetSubtitleDelay() {
    subtitleDelay = Duration.zero;
    try {
      (player.platform as dynamic)?.setProperty('sub-delay', '0');
    } catch (_) {}
  }

  void adjustAudioDelay(Duration delta) {
    audioDelay += delta;
    try {
      (player.platform as dynamic)?.setProperty(
        'audio-delay',
        (audioDelay.inMilliseconds / 1000.0).toString(),
      );
    } catch (_) {}
  }

  void resetAudioDelay() {
    audioDelay = Duration.zero;
    try {
      (player.platform as dynamic)?.setProperty('audio-delay', '0');
    } catch (_) {}
  }

  // Studio Equalizer & Night Mode (Dialogue Clarity & Dynamic Range Compression)
  bool isNightMode = false;
  String currentEqPreset = 'Flat';
  List<double> eqGains = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  static const List<String> eqBands = [
    '31Hz', '62Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'
  ];
  static const List<double> eqFrequencies = [
    31.25, 62.5, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0
  ];

  static const Map<String, List<double>> eqPresets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [6.0, 5.0, 4.0, 2.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Vocal Clarity': [-3.0, -2.0, 0.0, 2.0, 4.0, 4.5, 3.5, 2.0, 1.0, 0.0],
    'Movie Cinema': [4.0, 3.0, 1.5, 0.0, 0.0, 1.5, 2.5, 3.5, 4.0, 4.5],
    'Rock': [4.5, 3.0, 2.0, -1.0, -1.5, 1.0, 3.0, 4.0, 4.5, 5.0],
    'Pop': [-1.5, 1.0, 3.0, 4.0, 3.5, 1.5, -1.0, -1.5, -1.0, -1.5],
    'Electronic': [5.0, 4.0, 2.0, 0.0, -2.0, 2.0, 1.5, 2.5, 4.0, 4.5],
    'Classical': [4.0, 3.0, 2.5, 2.0, -1.5, -1.5, 0.0, 2.0, 3.0, 3.5],
  };

  void toggleNightMode() {
    isNightMode = !isNightMode;
    _applyAudioFilters();
  }

  void setEqPreset(String name) {
    if (eqPresets.containsKey(name)) {
      currentEqPreset = name;
      eqGains = List<double>.from(eqPresets[name]!);
      _applyAudioFilters();
    }
  }

  void setEqBand(int index, double gain) {
    if (index >= 0 && index < eqGains.length) {
      eqGains[index] = gain.clamp(-12.0, 12.0);
      currentEqPreset = 'Custom';
      _applyAudioFilters();
    }
  }

  void resetEq() {
    currentEqPreset = 'Flat';
    eqGains = List<double>.filled(10, 0.0);
    _applyAudioFilters();
  }

  void _applyAudioFilters() {
    final filters = <String>[];
    if (isNightMode) {
      // Dynamic range compressor for dialogue enhancement and preventing ear-splitting explosions
      filters.add('acompressor=threshold=-24dB:ratio=4:attack=200:release=1000');
    }
    final hasEq = eqGains.any((g) => g.abs() > 0.05);
    if (hasEq) {
      final eqParams = <String>[];
      for (int i = 0; i < eqGains.length; i++) {
        final f = eqFrequencies[i];
        final g = eqGains[i].toStringAsFixed(1);
        eqParams.add('equalizer=f=$f:width_type=o:w=1:g=$g');
      }
      filters.add(eqParams.join(','));
    }

    try {
      final afString = filters.join(',');
      (player.platform as dynamic)?.setProperty('af', afString);
    } catch (_) {}
  }

  // Video Adjustments via mpv properties
  void setBrightness(double value) {
    brightness = value;
    try {
      (player.platform as dynamic)?.setProperty('brightness', value.toInt().toString());
    } catch (_) {}
  }

  void setContrast(double value) {
    contrast = value;
    try {
      (player.platform as dynamic)?.setProperty('contrast', value.toInt().toString());
    } catch (_) {}
  }

  void setSaturation(double value) {
    saturation = value;
    try {
      (player.platform as dynamic)?.setProperty('saturation', value.toInt().toString());
    } catch (_) {}
  }

  void setGamma(double value) {
    gamma = value;
    try {
      (player.platform as dynamic)?.setProperty('gamma', value.toInt().toString());
    } catch (_) {}
  }

  void resetVideoAdjustments() {
    setBrightness(0.0);
    setContrast(0.0);
    setSaturation(0.0);
    setGamma(0.0);
  }

  void setAspectRatio(String? ratio) {
    currentAspectRatio = ratio;
    try {
      final val = (ratio == null || ratio == 'default') ? '-1' : ratio;
      (player.platform as dynamic)?.setProperty('video-aspect-override', val);
    } catch (_) {}
  }

  // Take Snapshot / Screenshot
  Future<String?> takeSnapshot() async {
    try {
      final bytes = await player.screenshot();
      if (bytes != null && bytes.isNotEmpty) {
        Directory dir = await getApplicationDocumentsDirectory();
        try {
          final picturesDir = Directory('${Platform.environment['USERPROFILE']}\\Pictures');
          if (picturesDir.existsSync()) {
            dir = picturesDir;
          }
        } catch (_) {}

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'AuraPlayer_Snapshot_$timestamp.png';
        final file = File('${dir.path}\\$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    player.dispose();
  }
}
