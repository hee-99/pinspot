// 카테고리별 평가 항목(위험도/난이도/맛 등) 하나를 정의하는 모델
class RatingDimension {
  final String key;
  final String label;
  final String emoji;
  final List<String> levelLabels; // index 0 = 1점 라벨, index 4 = 5점 라벨

  const RatingDimension({
    required this.key,
    required this.label,
    required this.emoji,
    required this.levelLabels,
  });

  // 평점(1~5)에 대응하는 라벨 문자열을 반환
  String labelFor(double rating) {
    final idx = (rating.round() - 1).clamp(0, 4);
    return levelLabels[idx];
  }
}

// 핀 카테고리마다 어떤 평가 항목들을 보여줄지 정의하는 스키마
class PinRatingSchema {
  // ── 평가 항목별 라벨/이모지/점수 단계 정의 ──────────────────────────
  static const _danger = RatingDimension(
    key: 'danger', label: '위험도', emoji: '⚠️',
    levelLabels: ['안전', '낮음', '보통', '높음', '매우높음'],
  );
  static const _difficulty = RatingDimension(
    key: 'difficulty', label: '난이도', emoji: '⛰️',
    levelLabels: ['매우쉬움', '쉬움', '보통', '어려움', '매우어려움'],
  );
  static const _scenery = RatingDimension(
    key: 'scenery', label: '경치', emoji: '🌄',
    levelLabels: ['평범', '보통', '좋음', '멋짐', '절경'],
  );
  static const _accessibility = RatingDimension(
    key: 'accessibility', label: '접근성', emoji: '🚶',
    levelLabels: ['매우어려움', '어려움', '보통', '쉬움', '매우쉬움'],
  );
  static const _facilities = RatingDimension(
    key: 'facilities', label: '시설', emoji: '🏕️',
    levelLabels: ['매우불량', '불량', '보통', '양호', '매우양호'],
  );
  static const _nature = RatingDimension(
    key: 'nature', label: '자연환경', emoji: '🌿',
    levelLabels: ['평범', '보통', '좋음', '멋짐', '절경'],
  );
  static const _waterQuality = RatingDimension(
    key: 'water_quality', label: '수질', emoji: '💧',
    levelLabels: ['매우탁함', '탁함', '보통', '맑음', '매우맑음'],
  );
  static const _taste = RatingDimension(
    key: 'taste', label: '맛', emoji: '😋',
    levelLabels: ['별로', '그럭저럭', '보통', '맛있음', '매우맛있음'],
  );
  static const _cleanliness = RatingDimension(
    key: 'cleanliness', label: '청결도', emoji: '✨',
    levelLabels: ['매우불결', '불결', '보통', '청결', '매우청결'],
  );
  static const _service = RatingDimension(
    key: 'service', label: '서비스', emoji: '💬',
    levelLabels: ['불친절', '약간불친절', '보통', '친절', '매우친절'],
  );
  static const _value = RatingDimension(
    key: 'value', label: '가성비', emoji: '💰',
    levelLabels: ['매우별로', '별로', '보통', '좋음', '매우좋음'],
  );
  static const _crowded = RatingDimension(
    key: 'crowded', label: '혼잡도', emoji: '👥',
    levelLabels: ['한산', '여유', '보통', '혼잡', '매우혼잡'],
  );
  static const _uniqueness = RatingDimension(
    key: 'uniqueness', label: '희귀도', emoji: '🔍',
    levelLabels: ['흔함', '약간흔함', '보통', '희귀', '매우희귀'],
  );

  // 카테고리명 → 해당 카테고리에서 사용할 평가 항목 목록 매핑
  static const Map<String, List<RatingDimension>> _schemas = {
    '등산/명산':      [_difficulty, _danger, _scenery],
    '계곡/자연':      [_danger, _waterQuality, _accessibility],
    '캠핑장':        [_facilities, _nature, _accessibility],
    '맛집':          [_taste, _cleanliness, _service, _value],
    '관광명소':       [_scenery, _accessibility, _crowded],
    '사진 명소':      [_scenery, _accessibility, _crowded],
    '폐허/어반':      [_danger, _uniqueness, _accessibility],
    '⚠️ 위험 지역':  [_danger, _accessibility],
    '조각상/공공예술': [_scenery, _accessibility],
  };

  // 카테고리명에 맞는 평가 항목 목록을 반환 (완전 일치 우선, 부분 일치로 폴백)
  static List<RatingDimension> forCategory(String category) {
    if (_schemas.containsKey(category)) return _schemas[category]!;
    for (final key in _schemas.keys) {
      if (category.contains(key) || key.contains(category)) return _schemas[key]!;
    }
    return [];
  }
}
