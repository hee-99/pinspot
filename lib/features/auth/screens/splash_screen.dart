import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _fadeController;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 위아래 바운스 (반동 느낌)
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -28.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -28.0, end: 4.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -12.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 2.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 5),
    ]).animate(_bounceController);

    // 핀 그림자 스케일 (땅에 닿을때 커지고 올라갈때 작아짐)
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.1).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.8).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.05).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 5),
    ]).animate(_bounceController);

    _fadeAnim = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // 반복 바운스 시작
    _bounceController.repeat();

    // 1.4초 후 페이드아웃 → 온보딩 or 로그인 화면
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (!mounted) return;
      _bounceController.stop();
      _fadeController.forward().then((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                onboardingDone ? const LoginScreen() : const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 핀 아이콘 + 그림자
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _bounceAnim.value),
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.primary,
                          size: 96,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 바닥 그림자 (핀이 내려올수록 커짐)
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 36,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              // 앱 이름
              const Text(
                'PINSPOT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '찍는 순간, 지도가 된다',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const Spacer(flex: 2),
              // 로딩 인디케이터
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '로딩 중...',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
