import 'dart:convert';

class RecentItem {
  final String path;
  final String title;
  final Duration position;
  final Duration duration;
  final DateTime lastPlayed;

  RecentItem({
    required this.path,
    required this.title,
    required this.position,
    required this.duration,
    required this.lastPlayed,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'title': title,
      'positionMs': position.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory RecentItem.fromMap(Map<String, dynamic> map) {
    return RecentItem(
      path: map['path'] as String,
      title: map['title'] as String,
      position: Duration(milliseconds: (map['positionMs'] as num?)?.toInt() ?? 0),
      duration: Duration(milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0),
      lastPlayed: DateTime.tryParse(map['lastPlayed'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RecentItem.fromJson(String source) =>
      RecentItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PlaylistItem {
  final String path;
  final String title;

  PlaylistItem({
    required this.path,
    required this.title,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistItem && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
