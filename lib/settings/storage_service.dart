import 'package:shared_preferences/shared_preferences.dart';
import '../player/player_models.dart';

class StorageService {
  static const String _keyRecentFiles = 'aura_recent_files';
  static const String _keyImportedFolders = 'aura_imported_folders';
  static const String _keyVolume = 'aura_volume';
  static const String _keyMuted = 'aura_muted';
  static const String _keySpeed = 'aura_speed';
  static const String _keyPositionPrefix = 'aura_pos_';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Volume
  double getVolume() => _prefs.getDouble(_keyVolume) ?? 100.0;
  Future<void> setVolume(double val) => _prefs.setDouble(_keyVolume, val);

  bool getMuted() => _prefs.getBool(_keyMuted) ?? false;
  Future<void> setMuted(bool val) => _prefs.setBool(_keyMuted, val);

  // Speed
  double getSpeed() => _prefs.getDouble(_keySpeed) ?? 1.0;
  Future<void> setSpeed(double val) => _prefs.setDouble(_keySpeed, val);

  // Resume positions
  Duration getPosition(String path) {
    final ms = _prefs.getInt('$_keyPositionPrefix$path');
    return Duration(milliseconds: ms ?? 0);
  }

  Future<void> setPosition(String path, Duration pos) async {
    await _prefs.setInt('$_keyPositionPrefix$path', pos.inMilliseconds);
  }

  // Recent files
  List<RecentItem> getRecentFiles() {
    final raw = _prefs.getStringList(_keyRecentFiles) ?? [];
    final list = <RecentItem>[];
    for (final itemStr in raw) {
      try {
        list.add(RecentItem.fromJson(itemStr));
      } catch (_) {}
    }
    return list;
  }

  Future<void> addRecentFile(RecentItem item) async {
    final current = getRecentFiles();
    current.removeWhere((e) => e.path == item.path);
    current.insert(0, item);
    if (current.length > 30) {
      current.removeRange(30, current.length);
    }
    final encoded = current.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_keyRecentFiles, encoded);
  }

  Future<void> clearRecentFiles() async {
    await _prefs.remove(_keyRecentFiles);
  }

  // Imported Library Folders
  List<String> getImportedFolders() {
    return _prefs.getStringList(_keyImportedFolders) ?? [];
  }

  Future<void> addImportedFolder(String folderPath) async {
    final current = getImportedFolders();
    if (!current.contains(folderPath)) {
      current.add(folderPath);
      await _prefs.setStringList(_keyImportedFolders, current);
    }
  }

  Future<void> removeImportedFolder(String folderPath) async {
    final current = getImportedFolders();
    current.remove(folderPath);
    await _prefs.setStringList(_keyImportedFolders, current);
  }
}
