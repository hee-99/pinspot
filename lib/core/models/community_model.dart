import 'package:flutter/material.dart';

// 커뮤니티(그룹) 정보를 표현하는 모델 — 이름/색상/멤버수/공개여부/참여코드 등
class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int colorValue;
  final int memberCount;
  final int pinCount;
  final bool isOwner;
  final bool isJoined;
  final bool isPrivate;
  final String? joinCode;
  final DateTime createdAt;
  final String? imagePath;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorValue,
    required this.memberCount,
    required this.pinCount,
    required this.isOwner,
    required this.isJoined,
    required this.isPrivate,
    this.joinCode,
    required this.createdAt,
    this.imagePath,
  });

  Color get color => Color(colorValue);

  // 로컬 저장(SharedPreferences)을 위해 JSON 맵으로 직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'colorValue': colorValue,
    'memberCount': memberCount,
    'pinCount': pinCount,
    'isOwner': isOwner,
    'isPrivate': isPrivate,
    'joinCode': joinCode,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
  };

  // JSON 맵을 CommunityModel로 역직렬화 (isJoined는 별도 상태이므로 파라미터로 주입)
  factory CommunityModel.fromJson(Map<String, dynamic> j, {bool isJoined = false}) =>
      CommunityModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        emoji: j['emoji'] as String,
        colorValue: j['colorValue'] as int,
        memberCount: j['memberCount'] as int,
        pinCount: j['pinCount'] as int,
        isOwner: j['isOwner'] as bool? ?? false,
        isPrivate: j['isPrivate'] as bool? ?? false,
        joinCode: j['joinCode'] as String?,
        isJoined: isJoined,
        createdAt: DateTime.parse(j['createdAt'] as String),
        imagePath: j['imagePath'] as String?,
      );

  // 일부 필드만 바꾼 새 인스턴스를 반환 (참여상태/핀수/멤버수/이미지 갱신용)
  CommunityModel copyWith({bool? isJoined, int? pinCount, int? memberCount, String? imagePath}) =>
      CommunityModel(
        id: id,
        name: name,
        description: description,
        emoji: emoji,
        colorValue: colorValue,
        memberCount: memberCount ?? this.memberCount,
        pinCount: pinCount ?? this.pinCount,
        isOwner: isOwner,
        isJoined: isJoined ?? this.isJoined,
        isPrivate: isPrivate,
        joinCode: joinCode,
        createdAt: createdAt,
        imagePath: imagePath ?? this.imagePath,
      );
}
