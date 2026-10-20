import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../settings/storage_service.dart';
import 'player_models.dart';

class AuraPlayerWrapper {
  final StorageService storageService;

  late final Player player;
  late final VideoController videoController;

  String? currentFilePath;
  String? currentTitle;
  Duration subtitleDelay = Duration.zero;

  AuraPlayerWrapper({required this.storageService}) {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'AuraPlayer',
        ready: null,
      ),
    );
    videoController = VideoController(player);

    // Save playback position periodically
    _initPositionSaver();
  }

  void _initPositionSaver() {
    player.stream.position.listen((pos) {
      final path = currentFilePath;
      if (path != null && pos.inSeconds > 2) {
        storageService.setPosition(path, pos);
      }
    });

    player.stream.completed.listen((completed) {
      if (completed && currentFilePath != null) {
        // Reset saved position if video reached the end
        storageService.setPosition(currentFilePath!, Duration.zero);
      }
    });
  }

  Future<void> openFile(String path, {String? title}) async {
    currentFilePath = path;
    currentTitle = title ?? path.split(RegExp(r'[/\\]')).last;

    // Check last saved position
    final lastPos = storageService.getPosition(path);

    await player.open(
      Media(path),
      play: true,
    );

    // Resume position if greater than 3 seconds
    if (lastPos.inSeconds > 3) {
      // Seek once duration is ready or after brief initialization
      Future.delayed(const Duration(milliseconds: 400), () {
        player.seek(lastPos);
      });
    }

    // Add to recents
    storageService.addRecentFile(
      RecentItem(
        path: path,
        title: currentTitle ?? 'Video',
        position: lastPos,
        duration: player.state.duration,
        lastPlayed: DateTime.now(),
      ),
    );
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> playOrPause() => player.playOrPause();

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
    final clamped = vol.clamp(0.0, 100.0);
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
    final clamped = rate.clamp(0.5, 2.0);
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
    // Notify listeners or update player subtitle delay if supported
  }

  Future<void> stop() async {
    currentFilePath = null;
    currentTitle = null;
    await player.stop();
  }

  void dispose() {
    player.dispose();
  }
}
