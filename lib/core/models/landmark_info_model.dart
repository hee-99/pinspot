import 'dart:convert';

class LandmarkInfo {
  final String placeName;
  final String origin;
  final String highlights;
  final String? bestTime;
  final String? tip;
  final DateTime fetchedAt;
  final String source; // 'gemini' | 'wikipedia'

  const LandmarkInfo({
    required this.placeName,
    required this.origin,
    required this.highlights,
    this.bestTime,
    this.tip,
    required this.fetchedAt,
    this.source = 'gemini',
  });

  bool get isStale => DateTime.now().difference(fetchedAt).inDays >= 30;

  String get suggestedDescription {
    final parts = <String>[];
    if (origin.isNotEmpty) parts.add(origin);
    if (highlights.isNotEmpty && highlights != origin) parts.add(highlights);
    if (tip != null && tip!.isNotEmpty && source != 'wikipedia') {
      parts.add('💡 ${tip!}');
    }
    return parts.join('\n\n');
  }

  String get sourceLabel => source == 'wikipedia' ? 'Wikipedia' : 'Gemini AI';

  Map<String, dynamic> toJson() => {
    'placeName': placeName,
    'origin': origin,
    'highlights': highlights,
    'bestTime': bestTime,
    'tip': tip,
    'fetchedAt': fetchedAt.toIso8601String(),
    'source': source,
  };

  factory LandmarkInfo.fromJson(Map<String, dynamic> j) => LandmarkInfo(
    placeName: j['placeName'] as String,
    origin: j['origin'] as String? ?? '',
    highlights: j['highlights'] as String? ?? '',
    bestTime: j['bestTime'] as String?,
    tip: j['tip'] as String?,
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
    source: j['source'] as String? ?? 'gemini',
  );

  static LandmarkInfo? tryParse(String raw) {
    try {
      return LandmarkInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
