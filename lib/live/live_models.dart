class LiveChannel {
  final String id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String category;
  final String country;
  final String language;
  final bool isHd;
  final String quality;

  const LiveChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.category = 'general',
    this.country = 'IN',
    this.language = 'Hindi',
    this.isHd = true,
    this.quality = 'HD',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'logoUrl': logoUrl,
        'category': category,
        'country': country,
        'language': language,
        'isHd': isHd,
        'quality': quality,
      };

  factory LiveChannel.fromJson(Map<String, dynamic> json) => LiveChannel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Live Stream',
        streamUrl: json['streamUrl'] as String? ?? '',
        logoUrl: json['logoUrl'] as String?,
        category: json['category'] as String? ?? 'general',
        country: json['country'] as String? ?? 'IN',
        language: json['language'] as String? ?? 'Hindi',
        isHd: json['isHd'] as bool? ?? true,
        quality: json['quality'] as String? ?? 'HD',
      );
}
