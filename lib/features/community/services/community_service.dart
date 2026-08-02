import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/core/models/community_model.dart';
import 'package:pinspot/core/models/pin_model.dart';

// 커뮤니티 CRUD 및 참여/핀 관리를 담당하는 서비스 (SharedPreferences 저장)
class CommunityService {
  static const _userKey = 'user_communities';
  static const _joinedKey = 'joined_community_ids';

  // 앱에 기본으로 노출되는 공개(시드) 커뮤니티 목록 — 하드코딩 목업 데이터
  static final _seeded = [
    CommunityModel(id: 'pub_1', name: '등산 마니아', description: '전국 명산을 함께 정복해요', emoji: '🏔️', colorValue: 0xFF4CAF50, memberCount: 2847, pinCount: 1203, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 1, 15)),
    CommunityModel(id: 'pub_2', name: '폐허 탐험대', description: '숨겨진 폐허와 어반 스팟 공유', emoji: '🏚️', colorValue: 0xFF795548, memberCount: 1256, pinCount: 892, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 2, 20)),
    CommunityModel(id: 'pub_3', name: '사진 명소 클럽', description: '인생샷 명소를 공유하는 커뮤니티', emoji: '📸', colorValue: 0xFFFF9800, memberCount: 4521, pinCount: 2103, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 3, 10)),
    CommunityModel(id: 'pub_4', name: '야경 헌터', description: '밤에 빛나는 도시 야경 핀 모음', emoji: '🌃', colorValue: 0xFF3F51B5, memberCount: 987, pinCount: 543, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 4, 5)),
    CommunityModel(id: 'pub_5', name: '계곡 & 워터폴', description: '청량한 계곡과 폭포를 찾아서', emoji: '💧', colorValue: 0xFF00BCD4, memberCount: 1834, pinCount: 721, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 5, 1)),
    CommunityModel(id: 'pub_6', name: '공공예술 탐방', description: '거리의 조각상과 벽화를 발견해요', emoji: '🗿', colorValue: 0xFF9C27B0, memberCount: 623, pinCount: 389, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 6, 12)),
  ];

  // 비공개 커뮤니티 초대용 6자리 참여 코드 생성 (혼동되는 문자 O/I/0/1 제외)
  static String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // 내가 만든 커뮤니티 + 공개 시드 커뮤니티를 합쳐서 참여 여부와 함께 반환
  static Future<List<CommunityModel>> getCommunities() async {
    final prefs = await SharedPreferences.getInstance();
    final joinedIds = Set<String>.from(prefs.getStringList(_joinedKey) ?? []);

    final userRaw = prefs.getStringList(_userKey) ?? [];
    final userCommunities = userRaw.map((e) {
      try {
        return CommunityModel.fromJson(
          json.decode(e) as Map<String, dynamic>,
          isJoined: true,
        );
      } catch (_) {
        return null;
      }
    }).whereType<CommunityModel>().toList();

    final publicWithStatus = _seeded
        .map((c) => c.copyWith(isJoined: joinedIds.contains(c.id)))
        .toList();

    return [...userCommunities, ...publicWithStatus];
  }

  // 새 커뮤니티를 생성해서 저장하고 생성자를 자동으로 참여 처리
  static Future<void> createCommunity(CommunityModel community) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_userKey) ?? [];
    list.add(json.encode(community.toJson()));
    await prefs.setStringList(_userKey, list);

    final joinedIds = List<String>.from(prefs.getStringList(_joinedKey) ?? []);
    if (!joinedIds.contains(community.id)) {
      joinedIds.add(community.id);
      await prefs.setStringList(_joinedKey, joinedIds);
    }
  }

  // 커뮤니티 참여/탈퇴 토글
  static Future<void> toggleJoin(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final joinedIds = List<String>.from(prefs.getStringList(_joinedKey) ?? []);
    if (joinedIds.contains(id)) {
      joinedIds.remove(id);
    } else {
      joinedIds.add(id);
    }
    await prefs.setStringList(_joinedKey, joinedIds);
  }

  /// Returns the community name on success, null if code not found.
  // 입력한 참여 코드로 비공개 커뮤니티를 찾아 참여 처리 (코드는 대소문자 무시하고 비교)
  static Future<CommunityModel?> joinByCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getStringList(_userKey) ?? [];
    final upperCode = code.trim().toUpperCase();

    // 저장된 모든 사용자 생성 커뮤니티를 순회하며 참여 코드가 일치하는지 검증
    for (final raw in userRaw) {
      try {
        final m = json.decode(raw) as Map<String, dynamic>;
        if ((m['joinCode'] as String?) == upperCode) {
          final community = CommunityModel.fromJson(m, isJoined: false);
          final joinedIds = List<String>.from(prefs.getStringList(_joinedKey) ?? []);
          if (!joinedIds.contains(community.id)) {
            joinedIds.add(community.id);
            await prefs.setStringList(_joinedKey, joinedIds);
          }
          return community;
        }
      } catch (_) {}
    }
    return null;
  }

  // ── 커뮤니티 핀 관리 ──────────────────────────────────────────────────────────

  static const _communityPinsPrefix = 'community_pins_';

  // 커뮤니티에 핀 공유 (동일 id 핀이 이미 있으면 중복 추가하지 않음)
  static Future<void> addCommunityPin(String communityId, PinModel pin) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_communityPinsPrefix$communityId';
    final list = prefs.getStringList(key) ?? [];
    final alreadyExists = list.any((e) {
      try { return (json.decode(e) as Map<String, dynamic>)['id'] == pin.id; }
      catch (_) { return false; }
    });
    if (!alreadyExists) {
      list.add(json.encode(pin.toJson()));
      await prefs.setStringList(key, list);
    }
  }

  // 특정 커뮤니티에 공유된 핀 목록 조회
  static Future<List<PinModel>> getCommunityPins(String communityId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_communityPinsPrefix$communityId') ?? [];
    return list.map((e) {
      try { return PinModel.fromJson(json.decode(e) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<PinModel>().toList();
  }


  // 내가 만든 커뮤니티를 삭제하고 참여 목록에서도 제거
  static Future<void> deleteCommunity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_userKey) ?? [];
    list.removeWhere((e) {
      try {
        return (json.decode(e) as Map<String, dynamic>)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_userKey, list);

    final joinedIds = List<String>.from(prefs.getStringList(_joinedKey) ?? []);
    joinedIds.remove(id);
    await prefs.setStringList(_joinedKey, joinedIds);
  }
}
