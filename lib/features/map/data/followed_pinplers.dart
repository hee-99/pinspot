import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 팔로우한 핀플러가 등록한 핀 하나의 위치 정보 (지도 마커용으로 LatLng을 직접 보유)
class FollowedPinLocation {
  final String name;
  final LatLng pos;
  const FollowedPinLocation(this.name, this.pos);
}

// "팔로우한 사람 지도 보기" 데모용 핀플러 한 명의 데이터
// 실제 팔로우/서버 연동 전까지 사용하는 하드코딩 목업 모델 (pinpler_ranking_screen.dart의 PinplerData/PinLocation 패턴 참고)
class FollowedPinpler {
  final String name;
  final String emoji;
  final Color color;
  final List<FollowedPinLocation> pins;

  const FollowedPinpler({
    required this.name,
    required this.emoji,
    required this.color,
    required this.pins,
  });
}

// 서버 연동 전까지 지도 화면에서 보여줄 "팔로우 중인 핀플러" 목업 리스트 (서울 근방 임의 좌표)
const followedPinplers = <FollowedPinpler>[
  FollowedPinpler(
    name: '산책왕지수',
    emoji: '🐿️',
    color: Color(0xFF2196F3),
    pins: [
      FollowedPinLocation('한강 노을 명당', LatLng(37.5285, 126.9326)),
      FollowedPinLocation('망원동 골목 카페', LatLng(37.5563, 126.9013)),
      FollowedPinLocation('하늘공원 억새길', LatLng(37.5714, 126.8895)),
    ],
  ),
  FollowedPinpler(
    name: '도시탐험가민',
    emoji: '🦊',
    color: Color(0xFFFF9800),
    pins: [
      FollowedPinLocation('을지로 노포 골목', LatLng(37.5663, 126.9910)),
      FollowedPinLocation('성수동 카페거리', LatLng(37.5445, 127.0560)),
      FollowedPinLocation('창신동 봉제거리', LatLng(37.5735, 127.0130)),
      FollowedPinLocation('종묘 돌담길', LatLng(37.5744, 126.9915)),
    ],
  ),
  FollowedPinpler(
    name: '야경헌터소율',
    emoji: '🦉',
    color: Color(0xFF9C27B0),
    pins: [
      FollowedPinLocation('낙산공원 야경', LatLng(37.5798, 127.0018)),
      FollowedPinLocation('N서울타워 전망', LatLng(37.5512, 126.9882)),
      FollowedPinLocation('반포대교 무지개분수', LatLng(37.5104, 126.9950)),
    ],
  ),
  FollowedPinpler(
    name: '카페인러버준',
    emoji: '🐨',
    color: Color(0xFF4CAF50),
    pins: [
      FollowedPinLocation('연남동 숨은 카페', LatLng(37.5636, 126.9256)),
      FollowedPinLocation('익선동 한옥 카페', LatLng(37.5735, 126.9903)),
    ],
  ),
];
