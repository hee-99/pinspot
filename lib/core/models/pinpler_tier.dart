import 'package:flutter/material.dart';

/// 핀플(Pinpler) 활동 등급 — 등록한 핀 개수를 기준으로 산정.
/// 등급이 오를수록 커뮤니티 개설 가능 개수 등 추가 권한이 열림.
enum PinplerTier { seed, active, veteran, master }

extension PinplerTierX on PinplerTier {
  // 등록한 핀 개수를 기준으로 해당하는 등급을 계산
  static PinplerTier fromPinCount(int count) {
    if (count >= 60) return PinplerTier.master;
    if (count >= 30) return PinplerTier.veteran;
    if (count >= 10) return PinplerTier.active;
    return PinplerTier.seed;
  }

  String get label => switch (this) {
    PinplerTier.seed => '새싹 핀플',
    PinplerTier.active => '액티브 핀플',
    PinplerTier.veteran => '베테랑 핀플',
    PinplerTier.master => '마스터 핀플',
  };

  String get badgeEmoji => switch (this) {
    PinplerTier.seed => '🌱',
    PinplerTier.active => '🔥',
    PinplerTier.veteran => '⭐',
    PinplerTier.master => '👑',
  };

  Color get color => switch (this) {
    PinplerTier.seed => const Color(0xFF8BC34A),
    PinplerTier.active => const Color(0xFFFF8A00),
    PinplerTier.veteran => const Color(0xFF7C4DFF),
    PinplerTier.master => const Color(0xFFFFB300),
  };

  /// 개설(소유)할 수 있는 커뮤니티 최대 개수.
  int get communityCreateLimit => switch (this) {
    PinplerTier.seed => 1,
    PinplerTier.active => 3,
    PinplerTier.veteran => 6,
    PinplerTier.master => 999,
  };

  /// 다음 등급까지 필요한 핀 개수. 최고 등급이면 -1.
  int get nextThreshold => switch (this) {
    PinplerTier.seed => 10,
    PinplerTier.active => 30,
    PinplerTier.veteran => 60,
    PinplerTier.master => -1,
  };
}
