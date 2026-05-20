import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_model.dart';

class CommunityService {
  static const _userKey = 'user_communities';
  static const _joinedKey = 'joined_community_ids';

  static final _seeded = [
    CommunityModel(id: 'pub_1', name: '등산 마니아', description: '전국 명산을 함께 정복해요', emoji: '🏔️', colorValue: 0xFF4CAF50, memberCount: 2847, pinCount: 1203, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 1, 15)),
    CommunityModel(id: 'pub_2', name: '폐허 탐험대', description: '숨겨진 폐허와 어반 스팟 공유', emoji: '🏚️', colorValue: 0xFF795548, memberCount: 1256, pinCount: 892, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 2, 20)),
    CommunityModel(id: 'pub_3', name: '사진 명소 클럽', description: '인생샷 명소를 공유하는 커뮤니티', emoji: '📸', colorValue: 0xFFFF9800, memberCount: 4521, pinCount: 2103, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 3, 10)),
    CommunityModel(id: 'pub_4', name: '야경 헌터', description: '밤에 빛나는 도시 야경 핀 모음', emoji: '🌃', colorValue: 0xFF3F51B5, memberCount: 987, pinCount: 543, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 4, 5)),
    CommunityModel(id: 'pub_5', name: '계곡 & 워터폴', description: '청량한 계곡과 폭포를 찾아서', emoji: '💧', colorValue: 0xFF00BCD4, memberCount: 1834, pinCount: 721, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 5, 1)),
    CommunityModel(id: 'pub_6', name: '공공예술 탐방', description: '거리의 조각상과 벽화를 발견해요', emoji: '🗿', colorValue: 0xFF9C27B0, memberCount: 623, pinCount: 389, isOwner: false, isJoined: false, isPrivate: false, createdAt: DateTime(2024, 6, 12)),
  ];

  static String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

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
  static Future<CommunityModel?> joinByCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getStringList(_userKey) ?? [];
    final upperCode = code.trim().toUpperCase();

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
