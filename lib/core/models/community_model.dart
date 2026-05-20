import 'package:flutter/material.dart';

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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'colorValue': colorValue,
    'memberCount': memberCount,
    'pinCount': pinCount,
    'isOwner': isOwner,
    'createdAt': createdAt.toIso8601String(),
  };

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
        isJoined: isJoined,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  CommunityModel copyWith({bool? isJoined, int? pinCount, int? memberCount}) =>
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
        createdAt: createdAt,
      );
}
