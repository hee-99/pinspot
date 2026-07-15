import 'package:flutter/material.dart';
import '../../../core/theme/tigo_colors.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';

class TigoAvatar extends StatelessWidget {
  final double size;
  final Map<TigoSlot, String> equipped;
  final bool showBase;

  const TigoAvatar({
    super.key,
    required this.size,
    required this.equipped,
    this.showBase = true,
  });

  @override
  Widget build(BuildContext context) {
    final equippedItems = kTigoItems
        .where((item) => equipped[item.slot] == item.id)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showBase)
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.2),
              child: Image.asset(
                'assets/tigo/tigo_hero.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          // 장착 아이템 이모지 뱃지 (우측 하단 ~ 우측 상단 방향으로 배치)
          for (int i = 0; i < equippedItems.length; i++)
            Positioned(
              right: -4,
              top: i * (size * 0.28),
              child: _EmojiBadge(
                emoji: equippedItems[i].emoji,
                badgeSize: size * 0.30,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  final String emoji;
  final double badgeSize;

  const _EmojiBadge({required this.emoji, required this.badgeSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: badgeSize * 0.52),
        ),
      ),
    );
  }
}
