import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/core/models/pin_model.dart';

// 최초 실행 시 데모용 샘플 핀을 SharedPreferences에 미리 채워주는 서비스 (디버그 빌드 전용)
class SampleDataService {
  static const _flagKey = 'sample_pins_seeded_v1';
  static const _pinsKey = 'saved_pins';

  // 아직 샘플 핀을 넣은 적이 없으면(플래그 미설정) 저장된 핀 목록에 샘플 핀들을 추가
  // release 빌드에서는 실행되지 않음 — 실사용자 지도를 목업 데이터로 채우지 않기 위함
  static Future<void> seedIfEmpty() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey) == true) return;
    await _insertSamplePins();
    await prefs.setBool(_flagKey, true);
  }

  // 관리자 화면에서 수동으로 호출하는 재시딩 — 빌드 모드와 무관하게 항상 실행
  static Future<void> seedManually() async {
    await _insertSamplePins();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flagKey, true);
  }

  // 저장된 핀 목록에서 id가 'sample_'로 시작하는 샘플 핀만 전부 제거
  static Future<int> clearSamplePins() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pinsKey) ?? [];
    final kept = <String>[];
    var removed = 0;
    for (final raw in existing) {
      final id = (json.decode(raw) as Map<String, dynamic>)['id'] as String?;
      if (id != null && id.startsWith('sample_')) {
        removed++;
      } else {
        kept.add(raw);
      }
    }
    await prefs.setStringList(_pinsKey, kept);
    return removed;
  }

  // 현재 저장된 핀 중 샘플 핀 개수
  static Future<int> sampleCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pinsKey) ?? [];
    return existing.where((raw) {
      final id = (json.decode(raw) as Map<String, dynamic>)['id'] as String?;
      return id != null && id.startsWith('sample_');
    }).length;
  }

  static Future<void> _insertSamplePins() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pinsKey) ?? [];
    final existingIds = existing.map((raw) => (json.decode(raw) as Map<String, dynamic>)['id'] as String?).toSet();
    final toAdd = _samplePins.where((p) => !existingIds.contains(p.id));
    final encoded = toAdd.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList(_pinsKey, [...existing, ...encoded]);
  }

  // 카테고리별(등산/계곡/캠핑/맛집/관광/사진/폐허) 데모용 샘플 핀 데이터
  static final _samplePins = <PinModel>[
    // ── 등산/명산 ─────────────────────────────────────────
    PinModel(
      id: 'sample_001',
      title: '북한산 백운대 정상',
      category: '등산/명산',
      description: '서울 근교 최고봉(836m). 정상에서 서울 도심 파노라마 뷰 압권. 주말 혼잡하니 새벽 출발 권장.',
      lat: 37.6586, lng: 126.9778,
      createdAt: DateTime(2026, 3, 12),
      ratings: {'difficulty': 4.0, 'danger': 2.0, 'scenery': 5.0},
    ),
    PinModel(
      id: 'sample_002',
      title: '설악산 대청봉',
      category: '등산/명산',
      description: '강원 최고봉(1708m). 단풍 시즌 9~10월이 최고. 오색약수터→대청봉 코스 추천.',
      lat: 38.1197, lng: 128.4661,
      createdAt: DateTime(2026, 4, 5),
      ratings: {'difficulty': 5.0, 'danger': 3.0, 'scenery': 5.0},
    ),
    PinModel(
      id: 'sample_003',
      title: '지리산 천왕봉',
      category: '등산/명산',
      description: '남한 제2봉(1915m). 일출 명소로 유명. 중산리 코스 기준 왕복 8~9시간 소요.',
      lat: 35.3349, lng: 127.7305,
      createdAt: DateTime(2026, 2, 20),
      ratings: {'difficulty': 5.0, 'danger': 2.0, 'scenery': 5.0},
    ),
    PinModel(
      id: 'sample_004',
      title: '도봉산 자운봉 뷰포인트',
      category: '등산/명산',
      description: '암릉 등반의 묘미. 서울 접근성 최고. 신선대에서 보는 자운봉 사진 스팟.',
      lat: 37.7062, lng: 127.0109,
      createdAt: DateTime(2026, 3, 28),
      ratings: {'difficulty': 3.0, 'danger': 2.0, 'scenery': 4.0},
    ),
    PinModel(
      id: 'sample_005',
      title: '관악산 연주대',
      category: '등산/명산',
      description: '서울대 입구에서 2시간. 연주대 기암에서 남산·한강 전망. 서울 야경 명소.',
      lat: 37.4427, lng: 126.9636,
      createdAt: DateTime(2026, 4, 15),
      ratings: {'difficulty': 3.0, 'danger': 2.0, 'scenery': 4.0},
    ),

    // ── 계곡/자연 ─────────────────────────────────────────
    PinModel(
      id: 'sample_006',
      title: '가평 용추계곡',
      category: '계곡/자연',
      description: '경기 최고 계곡 중 하나. 수심 얕고 물 맑음. 7~8월 주말 극혼잡, 평일 추천.',
      lat: 37.7882, lng: 127.5196,
      createdAt: DateTime(2026, 5, 10),
      ratings: {'danger': 2.0, 'water_quality': 5.0, 'accessibility': 4.0},
    ),
    PinModel(
      id: 'sample_007',
      title: '강원 내린천 래프팅 포인트',
      category: '계곡/자연',
      description: '인제군 최고 래프팅 명소. 급류 구간 다수, 전문 가이드 필수. 수질 청정.',
      lat: 38.0635, lng: 128.1543,
      createdAt: DateTime(2026, 5, 22),
      ratings: {'danger': 4.0, 'water_quality': 5.0, 'accessibility': 3.0},
    ),
    PinModel(
      id: 'sample_008',
      title: '제천 용하구곡',
      category: '계곡/자연',
      description: '소백산 자락 숨은 계곡 9곳. 차박·캠핑 허용 구간 있음. 가을 단풍도 명소.',
      lat: 36.9502, lng: 128.2149,
      createdAt: DateTime(2026, 4, 30),
      ratings: {'danger': 1.0, 'water_quality': 4.0, 'accessibility': 2.0},
    ),
    PinModel(
      id: 'sample_009',
      title: '순천 순천만 갈대밭',
      category: '계곡/자연',
      description: '국내 최대 갈대밭 습지. 10~11월 갈대 절정. 일몰 때 붉은 노을과 함께 장관.',
      lat: 34.8896, lng: 127.5015,
      createdAt: DateTime(2026, 3, 5),
      ratings: {'danger': 1.0, 'water_quality': 4.0, 'accessibility': 5.0},
    ),

    // ── 캠핑장 ────────────────────────────────────────────
    PinModel(
      id: 'sample_010',
      title: '가평 자라섬 오토캠핑장',
      category: '캠핑장',
      description: '섬 전체가 캠핑장. 전기 사이트 완비, 화장실·샤워실 청결. 예약 필수.',
      lat: 37.7941, lng: 127.4837,
      createdAt: DateTime(2026, 5, 1),
      ratings: {'facilities': 5.0, 'nature': 4.0, 'accessibility': 4.0},
    ),
    PinModel(
      id: 'sample_011',
      title: '양평 두물머리 캠핑',
      category: '캠핑장',
      description: '두 강이 만나는 명소 옆 캠핑지. 일출 명당. 주변 연꽃단지·카페 밀집.',
      lat: 37.5325, lng: 127.4931,
      createdAt: DateTime(2026, 4, 18),
      ratings: {'facilities': 3.0, 'nature': 5.0, 'accessibility': 4.0},
    ),
    PinModel(
      id: 'sample_012',
      title: '홍천 삼봉자연휴양림',
      category: '캠핑장',
      description: '국립 휴양림 내 캠핑. 계곡 바로 옆 사이트. 숲 속 힐링 캠핑의 정석.',
      lat: 37.8451, lng: 128.1089,
      createdAt: DateTime(2026, 5, 8),
      ratings: {'facilities': 4.0, 'nature': 5.0, 'accessibility': 3.0},
    ),

    // ── 맛집 ──────────────────────────────────────────────
    PinModel(
      id: 'sample_013',
      title: '전주 현대옥 본점',
      category: '맛집',
      description: '전주 콩나물국밥 원조. 진한 국물 + 아삭한 콩나물 조합. 24시간 운영, 줄 필수.',
      lat: 35.8204, lng: 127.1496,
      createdAt: DateTime(2026, 2, 14),
      ratings: {'taste': 5.0, 'cleanliness': 4.0, 'service': 3.0, 'value': 5.0},
    ),
    PinModel(
      id: 'sample_014',
      title: '부산 암소갈비집 (해운대)',
      category: '맛집',
      description: '해운대 50년 전통 갈비집. 두툼한 암소 생갈비. 점심 웨이팅 1시간 기본.',
      lat: 35.1629, lng: 129.1635,
      createdAt: DateTime(2026, 3, 20),
      ratings: {'taste': 5.0, 'cleanliness': 3.0, 'service': 4.0, 'value': 3.0},
    ),
    PinModel(
      id: 'sample_015',
      title: '서울 통인시장 도시락카페',
      category: '맛집',
      description: '엽전으로 반찬 구매해 도시락 조합. 종로 여행객 필수 코스. 오전 중 방문 추천.',
      lat: 37.5794, lng: 126.9698,
      createdAt: DateTime(2026, 4, 2),
      ratings: {'taste': 4.0, 'cleanliness': 4.0, 'service': 4.0, 'value': 5.0},
    ),
    PinModel(
      id: 'sample_016',
      title: '속초 아바이마을 순대국',
      category: '맛집',
      description: '실향민 음식문화 1번지. 오징어 순대 + 아바이 순대 세트 필수. 갯배 타고 이동.',
      lat: 38.2115, lng: 128.5917,
      createdAt: DateTime(2026, 5, 14),
      ratings: {'taste': 5.0, 'cleanliness': 3.0, 'service': 3.0, 'value': 4.0},
    ),

    // ── 관광명소 ──────────────────────────────────────────
    PinModel(
      id: 'sample_017',
      title: '경복궁 수문장 교대식',
      category: '관광명소',
      description: '오전 10시·오후 2시 하루 2회. 전통 복식 근위병 교대 의식. 외국인 관광객 인기 1위.',
      lat: 37.5796, lng: 126.9770,
      createdAt: DateTime(2026, 3, 1),
      ratings: {'scenery': 5.0, 'accessibility': 5.0, 'crowded': 4.0},
    ),
    PinModel(
      id: 'sample_018',
      title: '전주 한옥마을',
      category: '관광명소',
      description: '700여 채 전통 한옥 보존. 한복 체험·비빔밥·막걸리 골목. 주말 극혼잡.',
      lat: 35.8147, lng: 127.1531,
      createdAt: DateTime(2026, 2, 25),
      ratings: {'scenery': 5.0, 'accessibility': 5.0, 'crowded': 5.0},
    ),
    PinModel(
      id: 'sample_019',
      title: '제주 성산일출봉',
      category: '관광명소',
      description: '유네스코 세계자연유산. 일출 시간에 맞춰 정상 등반 권장. 우도 배편 근처.',
      lat: 33.4589, lng: 126.9426,
      createdAt: DateTime(2026, 1, 10),
      ratings: {'scenery': 5.0, 'accessibility': 4.0, 'crowded': 4.0},
    ),
    PinModel(
      id: 'sample_020',
      title: '해운대 해수욕장',
      category: '관광명소',
      description: '국내 최대 해수욕장. 여름 시즌 피서객 200만 이상. 마린시티 야경과 함께.',
      lat: 35.1587, lng: 129.1604,
      createdAt: DateTime(2026, 4, 25),
      ratings: {'scenery': 4.0, 'accessibility': 5.0, 'crowded': 5.0},
    ),

    // ── 사진 명소 ─────────────────────────────────────────
    PinModel(
      id: 'sample_021',
      title: '부산 감천문화마을',
      category: '사진 명소',
      description: '계단식 파스텔 주택 마을. 좁은 골목길 미로 탐방. 골목 곳곳 조형물·벽화.',
      lat: 35.0980, lng: 129.0104,
      createdAt: DateTime(2026, 3, 15),
      ratings: {'scenery': 5.0, 'accessibility': 3.0, 'crowded': 4.0},
    ),
    PinModel(
      id: 'sample_022',
      title: '서울 을지로 3가 골목',
      category: '사진 명소',
      description: '레트로 공업지대가 힙스터 거리로. 오래된 간판·쇠 냄새·노포 주점이 공존.',
      lat: 37.5660, lng: 126.9916,
      createdAt: DateTime(2026, 4, 8),
      ratings: {'scenery': 4.0, 'accessibility': 5.0, 'crowded': 3.0},
    ),
    PinModel(
      id: 'sample_023',
      title: '보성 녹차밭 대한다원',
      category: '사진 명소',
      description: '전남 보성 초록 카펫 같은 녹차밭. 봄~여름 싱그러운 녹색 물결. 안개 낀 아침이 최고.',
      lat: 34.7696, lng: 127.0791,
      createdAt: DateTime(2026, 5, 5),
      ratings: {'scenery': 5.0, 'accessibility': 3.0, 'crowded': 2.0},
    ),
    PinModel(
      id: 'sample_024',
      title: '서울 낙산공원 야경',
      category: '사진 명소',
      description: '한양도성길 위 낙산공원. 동대문·종로 야경 전망. 연인 데이트 코스 인기.',
      lat: 37.5798, lng: 127.0018,
      createdAt: DateTime(2026, 4, 20),
      ratings: {'scenery': 5.0, 'accessibility': 4.0, 'crowded': 2.0},
    ),

    // ── 폐허/어반 ─────────────────────────────────────────
    PinModel(
      id: 'sample_025',
      title: '성수동 폐공장 어반탐험',
      category: '폐허/어반',
      description: '1980년대 인쇄·제화 공장 밀집지역. 외벽 그라피티·녹슨 철골 피사체 풍부.',
      lat: 37.5443, lng: 127.0557,
      createdAt: DateTime(2026, 3, 30),
      ratings: {'danger': 2.0, 'uniqueness': 4.0, 'accessibility': 4.0},
    ),
    PinModel(
      id: 'sample_026',
      title: '인천 신포동 차이나타운 뒷골목',
      category: '폐허/어반',
      description: '개항기 근대 건물과 낡은 골목 혼재. 도시 재생 전 마지막 모습. 거리 사진가 성지.',
      lat: 37.4750, lng: 126.6174,
      createdAt: DateTime(2026, 2, 10),
      ratings: {'danger': 1.0, 'uniqueness': 4.0, 'accessibility': 4.0},
    ),
  ];
}
