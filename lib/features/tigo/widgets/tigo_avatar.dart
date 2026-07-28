import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';

/// 티고 아바타: 장착 아이템을 실제로 캐릭터에 겹쳐 그리는 페이퍼돌.
/// 래스터 자산 없이 CustomPainter로 직접 그려서(base/items PNG는 실제 그림이 없는
/// placeholder였음) 슬롯별 장착이 시각적으로 반영되도록 함.
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
    if (!showBase) return SizedBox(width: size, height: size);

    final itemIds = equipped.entries
        .where((e) => e.key != TigoSlot.skin)
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => _zIndexOf(a).compareTo(_zIndexOf(b)));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _TigoPainter(skinId: equipped[TigoSlot.skin], items: itemIds),
      ),
    );
  }

  static int _zIndexOf(String itemId) => tigoItemById(itemId)?.zIndex ?? 0;
}

class _TigoSkin {
  final Color body, belly, stripe, blush;
  const _TigoSkin({
    required this.body,
    required this.belly,
    required this.stripe,
    required this.blush,
  });
}

const _kClassicSkin = _TigoSkin(
  body: Color(0xFFFF8A00),
  belly: Color(0xFFFFF6E9),
  stripe: Color(0xFF2B2118),
  blush: Color(0xFFFFB199),
);
const _kSpecialSkin = _TigoSkin(
  body: Color(0xFFE9EEF3),
  belly: Color(0xFFFFFFFF),
  stripe: Color(0xFF8FA6B8),
  blush: Color(0xFFBFE0FF),
);
const _kGoldenSkin = _TigoSkin(
  body: Color(0xFFFFC94A),
  belly: Color(0xFFFFF3D0),
  stripe: Color(0xFFB07A00),
  blush: Color(0xFFFFD37A),
);

_TigoSkin _skinFor(String? skinId) {
  switch (skinId) {
    case 'skin_golden_tiger':
      return _kGoldenSkin;
    case 'skin_special':
      return _kSpecialSkin;
    default:
      return _kClassicSkin;
  }
}

const _kInk = Color(0xFF2B2118);

class _TigoPainter extends CustomPainter {
  final String? skinId;
  final List<String> items;

  const _TigoPainter({required this.skinId, required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final skin = _skinFor(skinId);
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    _paintBackdrop(canvas);
    _paintBody(canvas, skin);
    _paintHead(canvas, skin);

    for (final id in items) {
      switch (id) {
        case 'outfit_tshirt':
          _paintOutfit(canvas);
        case 'bag_hiking':
          _paintBag(canvas);
        case 'camera_vintage':
          _paintCamera(canvas);
        case 'hat_explorer':
          _paintHat(canvas);
        case 'badge_travel':
          _paintBadge(canvas);
      }
    }

    if (skinId == 'skin_golden_tiger') {
      _paintSparkles(canvas, const Color(0xFFFFE39A));
    } else if (skinId == 'skin_special') {
      _paintSparkles(canvas, const Color(0xFFDDEEFF));
    }

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(20),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFE3BF)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRRect(rect, paint);
  }

  void _paintBody(Canvas canvas, _TigoSkin skin) {
    final body = Path()
      ..moveTo(30, 100)
      ..quadraticBezierTo(28, 76, 38, 68)
      ..quadraticBezierTo(50, 62, 62, 68)
      ..quadraticBezierTo(72, 76, 70, 100)
      ..close();
    canvas.drawPath(body, Paint()..color = skin.body);

    final belly = Path()
      ..moveTo(42, 100)
      ..quadraticBezierTo(41, 84, 50, 80)
      ..quadraticBezierTo(59, 84, 58, 100)
      ..close();
    canvas.drawPath(belly, Paint()..color = skin.belly);
  }

  void _paintHead(Canvas canvas, _TigoSkin skin) {
    // 귀
    for (final dx in [-1.0, 1.0]) {
      final earCenter = Offset(50 + dx * 24, 20);
      canvas.drawCircle(earCenter, 13, Paint()..color = skin.body);
      canvas.drawCircle(earCenter, 6.5, Paint()..color = skin.belly);
    }

    // 얼굴
    canvas.drawCircle(const Offset(50, 44), 30, Paint()..color = skin.body);

    // 무늬(줄무늬)
    final stripePaint = Paint()
      ..color = skin.stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    void stripe(Offset start, Offset ctrl, Offset end) {
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        stripePaint,
      );
    }

    stripe(const Offset(30, 24), const Offset(26, 16), const Offset(32, 9));
    stripe(const Offset(70, 24), const Offset(74, 16), const Offset(68, 9));
    stripe(const Offset(23, 36), const Offset(17, 33), const Offset(19, 41));
    stripe(const Offset(77, 36), const Offset(83, 33), const Offset(81, 41));
    stripe(const Offset(50, 15), const Offset(50, 9), const Offset(50, 5));

    // 입 주변 흰 무늬
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 53), width: 38, height: 28),
      Paint()..color = skin.belly,
    );

    // 볼터치
    for (final dx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(50 + dx * 22, 56), width: 10, height: 6),
        Paint()..color = skin.blush.withValues(alpha: 0.55),
      );
    }

    // 눈
    for (final dx in [-1.0, 1.0]) {
      final eyeCenter = Offset(50 + dx * 12, 46);
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: 11, height: 13),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(eyeCenter.dx + dx * 1.2, eyeCenter.dy + 1.5),
        5,
        Paint()..color = _kInk,
      );
      canvas.drawCircle(
        Offset(eyeCenter.dx + dx * 1.2 - 1.6, eyeCenter.dy - 0.5),
        1.6,
        Paint()..color = Colors.white,
      );
    }

    // 코
    canvas.drawPath(
      Path()
        ..moveTo(46, 56)
        ..quadraticBezierTo(50, 53, 54, 56)
        ..quadraticBezierTo(50, 59.5, 46, 56)
        ..close(),
      Paint()..color = _kInk,
    );

    // 입
    final mouthPaint = Paint()
      ..color = _kInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(50, 58)
        ..lineTo(50, 61)
        ..quadraticBezierTo(46, 65, 42, 61)
        ..moveTo(50, 61)
        ..quadraticBezierTo(54, 65, 58, 61),
      mouthPaint,
    );
  }

  void _paintOutfit(Canvas canvas) {
    const shirt = Color(0xFF2F9E6E);
    const collar = Color(0xFF1F7A54);
    final path = Path()
      ..moveTo(33, 100)
      ..lineTo(33, 82)
      ..quadraticBezierTo(50, 74, 67, 82)
      ..lineTo(67, 100)
      ..close();
    canvas.drawPath(path, Paint()..color = shirt);
    canvas.drawPath(
      Path()
        ..moveTo(44, 80)
        ..quadraticBezierTo(50, 86, 56, 80),
      Paint()
        ..color = collar
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintBag(Canvas canvas) {
    const strap = Color(0xFF8A5A2B);
    const pack = Color(0xFF6E4423);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(13, 72, 12, 24), const Radius.circular(6)),
      Paint()..color = pack,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(75, 72, 12, 24), const Radius.circular(6)),
      Paint()..color = pack,
    );
    final strapPaint = Paint()
      ..color = strap
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(38, 70)..quadraticBezierTo(36, 85, 38, 100), strapPaint);
    canvas.drawPath(Path()..moveTo(62, 70)..quadraticBezierTo(64, 85, 62, 100), strapPaint);
  }

  void _paintCamera(Canvas canvas) {
    canvas.drawPath(
      Path()..moveTo(38, 78)..quadraticBezierTo(50, 88, 62, 78),
      Paint()
        ..color = const Color(0xFF3B3B3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(37, 84, 26, 18), const Radius.circular(4)),
      Paint()..color = const Color(0xFF4A4A4A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(46, 80, 8, 5), const Radius.circular(2)),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawCircle(const Offset(50, 93), 6.5, Paint()..color = const Color(0xFF1F1F1F));
    canvas.drawCircle(const Offset(50, 93), 4, Paint()..color = const Color(0xFF6FA8DC));
    canvas.drawRect(const Rect.fromLTWH(58, 86, 3, 3), Paint()..color = Colors.white70);
  }

  void _paintHat(Canvas canvas) {
    const khaki = Color(0xFFD9C48A);
    const khakiDark = Color(0xFFB89F5E);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 21), width: 56, height: 14),
      Paint()..color = khakiDark,
    );
    final dome = Path()
      ..moveTo(28, 21)
      ..quadraticBezierTo(30, 2, 50, 2)
      ..quadraticBezierTo(70, 2, 72, 21)
      ..close();
    canvas.drawPath(dome, Paint()..color = khaki);
    canvas.drawRect(const Rect.fromLTWH(28, 16, 44, 5), Paint()..color = const Color(0xFF7A5A2B));
    canvas.drawCircle(const Offset(50, 3), 2.4, Paint()..color = khakiDark);
  }

  void _paintBadge(Canvas canvas) {
    const center = Offset(66, 90);
    canvas.drawCircle(center, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      6.5,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawPath(_starPath(center, 5, 2.2, 5), Paint()..color = const Color(0xFFE0483E));
  }

  void _paintSparkles(Canvas canvas, Color color) {
    final paint = Paint()..color = color;
    for (final p in const [Offset(14, 30), Offset(87, 26), Offset(89, 62)]) {
      canvas.drawPath(_sparklePath(p, 5), paint);
    }
  }

  Path _starPath(Offset center, double outerR, double innerR, int points) {
    final path = Path();
    final step = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + i * step;
      final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  Path _sparklePath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.25, c.dy - r * 0.25, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.25, c.dy + r * 0.25, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.25, c.dy + r * 0.25, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.25, c.dy - r * 0.25, c.dx, c.dy - r)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _TigoPainter oldDelegate) =>
      oldDelegate.skinId != skinId || !listEquals(oldDelegate.items, items);
}
