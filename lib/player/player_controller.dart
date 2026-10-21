import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import '../settings/storage_service.dart';
import 'player_models.dart';

class AuraPlayerWrapper {
  final StorageService storageService;

  late final Player player;
  late final VideoController videoController;

  String? currentFilePath;
  String? currentTitle;
  Duration subtitleDelay = Duration.zero;

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

    // Apply resilient network properties for MPV live streaming
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

    // Save playback position periodically (only for offline videos)
    _initPositionSaver();
  }

  void _initPositionSaver() {
    player.stream.position.listen((pos) {
      final path = currentFilePath;
      // Never save live stream position
      if (path != null && !path.startsWith('http://') && !path.startsWith('https://')) {
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
    final clamped = vol.clamp(0.0, 150.0);
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
