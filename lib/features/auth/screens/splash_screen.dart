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

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowScale;

  late final AnimationController _exitCtrl;
  late final Animation<double> _exitOpacity;

  Widget? _next;

  @override
  void initState() {
    super.initState();

    // ── 인트로 1200ms ─────────────────────────────────────────────────────────
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

    // ── 바운스 (700ms 반복) ────────────────────────────────────────────────────
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bounceY = Tween<double>(begin: 0.0, end: -16.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    // ── 글로우 펄스 (1600ms 반복) ──────────────────────────────────────────────
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _glowScale = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ── 종료 350ms ────────────────────────────────────────────────────────────
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

    await Future.wait([
      _resolveNext(),
      Future<void>.delayed(const Duration(milliseconds: 2900)),
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
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introCtrl, _bounceCtrl, _glowCtrl, _exitCtrl]),
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

                      // ── 핀 아이콘 + 글로우 링 (바운스 블록) ───────────────────
                      Transform.translate(
                        offset: Offset(0, _bounceY.value),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 외곽 글로우 링
                            Transform.scale(
                              scale: _glowScale.value,
                              child: Opacity(
                                opacity: _pinFade.value * 0.22,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 중간 글로우 링
                            Transform.scale(
                              scale: _glowScale.value * 0.72,
                              child: Opacity(
                                opacity: _pinFade.value * 0.32,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 핀 아이콘
                            Transform.scale(
                              scale: _pinScale.value,
                              child: Opacity(
                                opacity: _pinFade.value,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.55),
                                        blurRadius: 36,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.22),
                                        blurRadius: 72,
                                        spreadRadius: 10,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── "찍는 순간," ──────────────────────────────────────────
                      Opacity(
                        opacity: _line1Fade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _line1Fade.value) * 22),
                          child: const Text(
                            '찍는 순간,',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.2,
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
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1.2,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 5),

                      // ── PINSPOT 워드마크 ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 52),
                        child: Opacity(
                          opacity: _wordmarkFade.value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'PINSPOT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  letterSpacing: 5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _SplashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 메인 다크 그라디언트
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkBg, AppColors.darkBgMid],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // 중앙 방사형 그린 글로우
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

    // 흩어진 핀 도트 (지도 느낌)
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
