import 'dart:convert';

// AI(Gemini)나 위키백과에서 조회한 랜드마크(장소) 정보를 담는 모델, 캐시 만료 여부 포함
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

  // 조회한 지 30일 이상 지났으면 오래된 캐시로 간주해 재조회 대상으로 취급
  bool get isStale => DateTime.now().difference(fetchedAt).inDays >= 30;

  // 유래/특징/팁 정보를 하나의 설명 문구로 합쳐 핀 등록 시 제안 문구로 사용
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

  // 캐시 저장을 위해 JSON 맵으로 직렬화
  Map<String, dynamic> toJson() => {
    'placeName': placeName,
    'origin': origin,
    'highlights': highlights,
    'bestTime': bestTime,
    'tip': tip,
    'fetchedAt': fetchedAt.toIso8601String(),
    'source': source,
  };

  // JSON 맵을 LandmarkInfo로 역직렬화
  factory LandmarkInfo.fromJson(Map<String, dynamic> j) => LandmarkInfo(
    placeName: j['placeName'] as String,
    origin: j['origin'] as String? ?? '',
    highlights: j['highlights'] as String? ?? '',
    bestTime: j['bestTime'] as String?,
    tip: j['tip'] as String?,
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
    source: j['source'] as String? ?? 'gemini',
  );

  // 파싱 실패 시 예외 대신 null을 반환하는 안전한 파싱 헬퍼
  static LandmarkInfo? tryParse(String raw) {
    try {
      return LandmarkInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
