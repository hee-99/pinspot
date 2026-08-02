import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/account/auth/services/auth_service.dart';
import 'package:pinspot/account/auth/services/sample_data_service.dart';
import 'package:pinspot/features/tigo/services/tigo_service.dart';
import 'package:pinspot/features/tigo/services/tigo_purchase_service.dart';
import 'package:pinspot/features/home/screens/home_screen.dart';
import 'package:pinspot/account/auth/screens/login_screen.dart';
import 'package:pinspot/account/auth/screens/onboarding_screen.dart';

// 앱 최초 진입 시 보여지는 스플래시 화면 (다크 배경 + 핀 아이콘 애니메이션)
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

  // 인트로/바운스/글로우 애니메이션을 시작하고 다음 화면 결정 후 전환
  Future<void> _start() async {
    _introCtrl.forward().then((_) {
      if (mounted) {
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

  // 온보딩 완료 여부·로그인 상태를 확인해 다음에 보여줄 화면을 결정
  Future<void> _resolveNext() async {
    // 스토어 조회는 느릴 수 있어 스플래시 전환을 막지 않도록 fire-and-forget으로 시작.
    unawaited(TigoPurchaseService.instance.init());

    final results = await Future.wait([
      SharedPreferences.getInstance(),
      TigoService.instance.load(),
      SampleDataService.seedIfEmpty(),
      AuthService.isLoggedIn(),
    ]);
    final prefs = results[0] as SharedPreferences;
    final loggedIn = results[3] as bool;
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
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
                      Stack(
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
                            // 티고 심볼 (앱 아이콘과 동일한 이미지)
                            Transform.scale(
                              scale: _pinScale.value,
                              child: Opacity(
                                opacity: _pinFade.value,
                                child: Image.asset(
                                  'assets/tigo/app_icon_fg_v2.png',
                                  width: 128,
                                  height: 128,
                                ),
                              ),
                            ),
                          ],
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

                      // ── "지도가 된다" ──────────────────────────────────────────
                      Opacity(
                        opacity: _line2Fade.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _line2Fade.value) * 22),
                          child: const Text(
                            '지도가 된다',
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
                                  'TIGO',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary.withValues(alpha: 0.85),
                                    letterSpacing: 8,
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

// 스플래시 배경의 그라데이션 + 은은한 점 패턴을 그리는 커스텀 페인터
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
