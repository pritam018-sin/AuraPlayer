import 'package:media_kit/media_kit.dart';

class TrackFormatters {
  static const Map<String, String> _isoLanguages = {
    'eng': 'English',
    'en': 'English',
    'hin': 'Hindi',
    'hi': 'Hindi',
    'spa': 'Spanish',
    'es': 'Spanish',
    'fre': 'French',
    'fra': 'French',
    'fr': 'French',
    'ger': 'German',
    'deu': 'German',
    'de': 'German',
    'jpn': 'Japanese',
    'ja': 'Japanese',
    'kor': 'Korean',
    'ko': 'Korean',
    'chi': 'Chinese',
    'zho': 'Chinese',
    'zh': 'Chinese',
    'rus': 'Russian',
    'ru': 'Russian',
    'por': 'Portuguese',
    'pt': 'Portuguese',
    'ita': 'Italian',
    'it': 'Italian',
    'ara': 'Arabic',
    'ar': 'Arabic',
    'tam': 'Tamil',
    'ta': 'Tamil',
    'tel': 'Telugu',
    'te': 'Telugu',
    'ben': 'Bengali',
    'bn': 'Bengali',
    'kan': 'Kannada',
    'kn': 'Kannada',
    'mal': 'Malayalam',
    'ml': 'Malayalam',
    'mar': 'Marathi',
    'mr': 'Marathi',
    'guj': 'Gujarati',
    'gu': 'Gujarati',
    'pan': 'Punjabi',
    'pa': 'Punjabi',
    'urd': 'Urdu',
    'ur': 'Urdu',
    'vie': 'Vietnamese',
    'vi': 'Vietnamese',
    'tha': 'Thai',
    'th': 'Thai',
    'ind': 'Indonesian',
    'id': 'Indonesian',
    'tur': 'Turkish',
    'tr': 'Turkish',
    'pol': 'Polish',
    'pl': 'Polish',
    'ukr': 'Ukrainian',
    'uk': 'Ukrainian',
    'swe': 'Swedish',
    'sv': 'Swedish',
    'nor': 'Norwegian',
    'no': 'Norwegian',
    'dan': 'Danish',
    'da': 'Danish',
    'fin': 'Finnish',
    'fi': 'Finnish',
    'dut': 'Dutch',
    'nld': 'Dutch',
    'nl': 'Dutch',
    'ell': 'Greek',
    'el': 'Greek',
    'heb': 'Hebrew',
    'he': 'Hebrew',
    'hun': 'Hungarian',
    'hu': 'Hungarian',
    'ces': 'Czech',
    'cs': 'Czech',
    'ron': 'Romanian',
    'ro': 'Romanian',
  };

  /// Format an AudioTrack matching VLC's professional track nomenclature
  static String formatAudioTrack(AudioTrack track, {int? index}) {
    // 1. Language resolution
    String? lang;
    if (track.language != null && track.language!.isNotEmpty) {
      final code = track.language!.toLowerCase().trim();
      if (code != 'und' && code != 'unk') {
        lang = _isoLanguages[code] ?? (code.length <= 3 ? code.toUpperCase() : code);
      }
    }

    // 2. Title resolution
    String? title = track.title?.trim();
    if (title != null && title.isNotEmpty) {
      for (final entry in _isoLanguages.entries) {
        if (title.toLowerCase().contains(entry.value.toLowerCase())) {
          lang ??= entry.value;
          break;
        }
      }
    }

    // 3. Channel layout (Mono, Stereo, 5.1 Surround, 7.1, etc.)
    String? channelDesc;
    final ch = track.audiochannels ?? track.channelscount;
    if (ch != null && ch > 0) {
      if (ch == 1) {
        channelDesc = 'Mono';
      } else if (ch == 2) {
        channelDesc = 'Stereo';
      } else if (ch == 6) {
        channelDesc = '5.1 Surround';
      } else if (ch == 8) {
        channelDesc = '7.1 Surround';
      } else {
        channelDesc = '$ch Channels';
      }
    } else if (track.channels != null && track.channels!.isNotEmpty) {
      channelDesc = track.channels;
    }

    // 4. Codec description (AAC, AC3, EAC3, DTS, FLAC)
    String? codecDesc;
    if (track.codec != null && track.codec!.isNotEmpty) {
      codecDesc = track.codec!.toUpperCase();
    }

    final techParts = <String>[];
    if (channelDesc != null) techParts.add(channelDesc);
    if (codecDesc != null) techParts.add(codecDesc);
    final techString = techParts.isNotEmpty ? ' [${techParts.join(' • ')}]' : '';

    String baseName;
    if (lang != null) {
      if (title != null && title.isNotEmpty && !title.toLowerCase().contains(lang.toLowerCase())) {
        baseName = '$lang ($title)';
      } else {
        baseName = lang;
      }
    } else if (title != null && title.isNotEmpty) {
      baseName = title;
    } else {
      baseName = 'Audio Track ${index ?? track.id}';
    }

    if (track.isDefault == true) {
      return '$baseName$techString ★ Default';
    }
    return '$baseName$techString';
  }

  /// Format a SubtitleTrack matching VLC's professional track nomenclature
  static String formatSubtitleTrack(SubtitleTrack track, {int? index}) {
    if (track.id == 'no') return 'Off (Subtitles Disabled)';

    final isExternal = track.id.startsWith('external_') ||
        (track.title != null &&
            (track.title!.endsWith('.srt') ||
                track.title!.endsWith('.ass') ||
                track.title!.endsWith('.vtt') ||
                track.title!.contains('\\') ||
                track.title!.contains('/')));

    String? lang;
    if (track.language != null && track.language!.isNotEmpty) {
      final code = track.language!.toLowerCase().trim();
      if (code != 'und' && code != 'unk') {
        lang = _isoLanguages[code] ?? (code.length <= 3 ? code.toUpperCase() : code);
      }
    }

    String? title = track.title?.trim();
    if (isExternal && title != null) {
      final filename = title.split(RegExp(r'[/\\]')).last;
      for (final entry in _isoLanguages.entries) {
        final regex = RegExp(
          r'\b(' + RegExp.escape(entry.key) + r'|' + RegExp.escape(entry.value) + r')\b',
          caseSensitive: false,
        );
        if (regex.hasMatch(filename) || filename.toLowerCase().contains(entry.value.toLowerCase())) {
          lang ??= entry.value;
          break;
        }
      }
      final cleanName = filename.replaceAll(RegExp(r'\.(srt|ass|vtt|sub)$', caseSensitive: false), '');
      if (lang != null) {
        return '$lang [External Subtitle]';
      }
      return '$cleanName [External]';
    }

    String? codecTag;
    if (track.codec != null && track.codec!.isNotEmpty) {
      final c = track.codec!.toLowerCase();
      if (c.contains('subrip') || c == 'srt') {
        codecTag = 'SRT';
      } else if (c.contains('ass') || c.contains('ssa')) {
        codecTag = 'ASS';
      } else if (c.contains('pgs') || c.contains('hdmv')) {
        codecTag = 'PGS';
      } else if (c.contains('vobsub')) {
        codecTag = 'VobSub';
      } else {
        codecTag = c.toUpperCase();
      }
    }

    String? specialFlag;
    if (title != null && title.isNotEmpty) {
      final tLow = title.toLowerCase();
      if (tLow.contains('forced')) {
        specialFlag = 'Forced';
      } else if (tLow.contains('sdh') || tLow.contains('cc')) {
        specialFlag = 'SDH';
      } else if (tLow.contains('commentary')) {
        specialFlag = 'Commentary';
      }
      if (lang == null) {
        for (final entry in _isoLanguages.entries) {
          if (tLow.contains(entry.value.toLowerCase())) {
            lang = entry.value;
            break;
          }
        }
      }
    }

    final tags = <String>[];
    if (codecTag != null) tags.add(codecTag);
    if (specialFlag != null) tags.add(specialFlag);
    final tagString = tags.isNotEmpty ? ' [${tags.join(' • ')}]' : '';

    String baseName;
    if (lang != null) {
      baseName = lang;
    } else if (title != null && title.isNotEmpty && !title.toLowerCase().startsWith('track')) {
      baseName = title;
    } else {
      baseName = 'Subtitle ${index ?? track.id}';
    }

    if (track.isDefault == true) {
      return '$baseName$tagString ★ Default';
    }
    return '$baseName$tagString';
  }
}
