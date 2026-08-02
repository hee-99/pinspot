import 'package:flutter/material.dart';
import 'package:pinspot/design/theme/tigo_colors.dart';
import 'package:pinspot/features/tigo/models/tigo_model.dart';
import 'package:pinspot/features/tigo/widgets/tigo_avatar.dart';

// 새 티고 아이템을 해금했을 때 띄우는 축하 다이얼로그
class TigoUnlockDialog extends StatelessWidget {
  final List<TigoItem> items;

  const TigoUnlockDialog({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final item = items.first;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: TigoColors.cream,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: TigoColors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '새 아이템 획득!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: TigoColors.brown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '「${item.name}」을(를) 획득했어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: TigoColors.brown.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            if (items.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                '외 ${items.length - 1}개 더',
                style: TextStyle(fontSize: 13, color: TigoColors.orange),
              ),
            ],
            const SizedBox(height: 20),
            TigoAvatar(
              size: 100,
              equipped: {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TigoColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('도감에서 장착하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
