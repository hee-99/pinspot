import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final Animation<double> _pinScale;
  late final Animation<double> _pinFade;
  late final Animation<double> _line1Fade;
  late final Animation<double> _line2Fade;
  late final Animation<double> _wordmarkFade;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceY;
  late final Animation<double> _squishY; // 착지 시 납작 효과

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowScale;

  late final AnimationController _progressCtrl;

  late final AnimationController _exitCtrl;
  late final Animation<double> _exitOpacity;

  Widget? _next;

  static const _totalDuration = Duration(milliseconds: 2900);

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

    _pinScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack)),
    );
    _pinFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: const Interval(0.0, 0.28)),
    );
    _line1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: const Interval(0.32, 0.62)),
    );
    _line2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: const Interval(0.52, 0.82)),
    );
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: const Interval(0.74, 1.0)),
    );

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _bounceY = Tween<double>(begin: 0.0, end: -18.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
    // 공중에 있을 때 1.0, 착지 직전 0.82 (납작), 다시 1.0
    _squishY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _glowScale = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(vsync: this, duration: _totalDuration);

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_exitCtrl);

    _start();
  }

  Future<void> _start() async {
    _introCtrl.forward().then((_) {
      if (mounted) {
        _bounceCtrl.repeat(reverse: true);
        _glowCtrl.repeat(reverse: true);
      }
    });
    _progressCtrl.forward();

    await Future.wait([
      _resolveNext(),
      Future<void>.delayed(_totalDuration),
    ]);

    if (!mounted) return;
    _bounceCtrl.stop();
    _glowCtrl.stop();
    await _exitCtrl.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => _next!,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  Future<void> _resolveNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final loggedIn = await AuthService.isLoggedIn();
    _next = !onboardingDone
        ? const OnboardingScreen()
        : loggedIn
            ? const HomeScreen()
            : const LoginScreen();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    _progressCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introCtrl, _bounceCtrl, _glowCtrl, _exitCtrl, _progressCtrl]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Scaffold(
            backgroundColor: AppColors.darkBg,
            body: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _SplashBgPainter())),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 5),

                      // ── 핀 아이콘 + 글로우 링 ──────────────────────────────────
                      Transform.translate(
                        offset: Offset(0, _bounceY.value),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 외곽 글로우
                            Transform.scale(
                              scale: _glowScale.value,
                              child: Opacity(
                                opacity: _pinFade.value * 0.18,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 1.0),
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _glowScale.value * 0.70,
                              child: Opacity(
                                opacity: _pinFade.value * 0.28,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            // 귀여운 핀 캐릭터
                            Transform.scale(
                              scale: _pinScale.value,
                              child: Opacity(
                                opacity: _pinFade.value,
                                child: SizedBox(
                                  width: 110,
                                  height: 128,
                                  child: CustomPaint(
                                    painter: _PinIconPainter(squishY: _squishY.value),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 52),

                      // ── "찍는 순간," ──────────────────────────────────────────
                      Opacity(
                        opacity: _line1Fade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _line1Fade.value) * 22),
                          child: const Text(
                            '찍는 순간,',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.4,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── "기록이 된다" ──────────────────────────────────────────
                      Opacity(
                        opacity: _line2Fade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _line2Fade.value) * 22),
                          child: const Text(
                            '기록이 된다',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1.4,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 5),

                      // ── PINSPOT 워드마크 ──────────────────────────────────────
                      Opacity(
                        opacity: _wordmarkFade.value,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'PINSPOT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary.withValues(alpha: 0.65),
                                    letterSpacing: 6,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // 로딩 프로그레스 바
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 60),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 2,
                                  child: LinearProgressIndicator(
                                    value: _progressCtrl.value,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary.withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 52),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 귀여운 핀 캐릭터 (앱 아이콘과 동일한 디자인)
class _PinIconPainter extends CustomPainter {
  final double squishY; // 1.0 = 정상, <1.0 = 착지 시 납작해짐
  const _PinIconPainter({this.squishY = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final headR  = w * 0.36;
    final headCy = h * 0.52 / squishY;
    final tailY  = h * 0.90;

    // ── 글로우 그림자 ──────────────────────────────────────
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawPath(_pinPath(cx, headCy, headR, tailY, squishY), glowPaint);

    // ── 핀 흰색 몸통 ──────────────────────────────────────
    canvas.drawPath(
      _pinPath(cx, headCy, headR, tailY, squishY),
      Paint()..color = Colors.white,
    );

    // ── 눈 ───────────────────────────────────────────────
    final eyeY   = headCy - headR - w * 0.01;
    final eyeR   = w * 0.082;
    final eyeGap = w * 0.156;

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeGap;
      canvas.drawCircle(Offset(ex, eyeY), eyeR, Paint()..color = const Color(0xFF161616));
      canvas.drawCircle(
        Offset(ex - eyeR * 0.28, eyeY - eyeR * 0.32),
        eyeR * 0.26,
        Paint()..color = Colors.white,
      );
    }

    // ── 미소 ─────────────────────────────────────────────
    final smilePaint = Paint()
      ..color = const Color(0xFF12642A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    final smileRect = Rect.fromCenter(
      center: Offset(cx, eyeY + w * 0.072),
      width: w * 0.20,
      height: w * 0.10,
    );
    canvas.drawArc(smileRect, 0.28, 2.58, false, smilePaint);

    // ── 발 그림자 타원 ────────────────────────────────────
    final shadowW = w * 0.28 * squishY;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, tailY + h * 0.03), width: shadowW, height: h * 0.04),
      Paint()..color = AppColors.primary.withValues(alpha: 0.30),
    );
  }

  Path _pinPath(double cx, double headCy, double headR, double tailY, double squishY) {
    const neckDeg = 42.0;
    final path = Path();
    final pts = <Offset>[];
    final arcSpan = 360.0 - (180.0 - neckDeg - neckDeg);
    const steps = 80;
    for (int i = 0; i <= steps; i++) {
      final a = (neckDeg - arcSpan * i / steps) * 3.14159265 / 180.0;
      pts.add(Offset(
        cx + headR * math.cos(a),
        headCy + headR * math.sin(a) * squishY,
      ));
    }
    pts.add(Offset(cx, tailY));
    path.addPolygon(pts, true);
    return path;
  }

  @override
  bool shouldRepaint(covariant _PinIconPainter old) => old.squishY != squishY;
}

class _SplashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkBg, AppColors.darkBgMid],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final center = Offset(size.width / 2, size.height * 0.43);
    canvas.drawCircle(
      center,
      size.width * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.58)),
    );

    final dotPaint = Paint();
    for (final d in [
      [0.10, 0.12, 2.5, 0.18],
      [0.88, 0.08, 2.0, 0.14],
      [0.84, 0.73, 2.5, 0.12],
      [0.12, 0.83, 2.0, 0.12],
      [0.95, 0.54, 1.5, 0.10],
      [0.46, 0.05, 2.5, 0.16],
      [0.03, 0.45, 1.5, 0.11],
      [0.68, 0.90, 2.0, 0.10],
      [0.57, 0.19, 1.5, 0.13],
      [0.28, 0.66, 2.0, 0.09],
      [0.76, 0.36, 1.5, 0.11],
      [0.34, 0.29, 2.0, 0.12],
      [0.92, 0.32, 1.5, 0.09],
      [0.20, 0.50, 1.5, 0.10],
    ]) {
      dotPaint.color = AppColors.primary.withValues(alpha: d[3]);
      canvas.drawCircle(Offset(size.width * d[0], size.height * d[1]), d[2], dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
