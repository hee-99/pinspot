import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _loadingProvider;

  Future<void> _login(String provider) async {
    setState(() => _loadingProvider = provider);
    try {
      final user = switch (provider) {
        'kakao'  => await AuthService.signInWithKakao(),
        'naver'  => await AuthService.signInWithNaver(),
        'apple'  => await AuthService.signInWithApple(),
        _        => null,
      };

      if (!mounted) return;

      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (provider == 'apple') {
        _snack('Apple 로그인은 iOS에서만 지원합니다');
      }
      // kakao/naver: null == 사용자가 취소한 경우 → 별도 메시지 없음
    } catch (e) {
      if (mounted) _snack('로그인 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const Text(
                'PINSPOT',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '찍는 순간, 지도가 된다',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const Spacer(flex: 3),
              _LoginButton(
                provider: 'kakao',
                label: '카카오로 시작하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF3C1E1E),
                icon: _KakaoIcon(),
                loading: _loadingProvider == 'kakao',
                onTap: () => _login('kakao'),
              ),
              const SizedBox(height: 12),
              _LoginButton(
                provider: 'naver',
                label: '네이버로 시작하기',
                backgroundColor: const Color(0xFF03C75A),
                textColor: Colors.white,
                icon: const _NaverIcon(),
                loading: _loadingProvider == 'naver',
                onTap: () => _login('naver'),
              ),
              const SizedBox(height: 12),
              _LoginButton(
                provider: 'apple',
                label: 'Apple로 시작하기',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                loading: _loadingProvider == 'apple',
                onTap: () => _login('apple'),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의합니다',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String provider;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final bool loading;
  final VoidCallback onTap;

  const _LoginButton({
    required this.provider,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: Center(child: icon)),
                const Spacer(),
                loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                const Spacer(),
                const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KakaoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('K', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3C1E1E)));
  }
}

class _NaverIcon extends StatelessWidget {
  const _NaverIcon();

  @override
  Widget build(BuildContext context) {
    return const Text('N', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white));
  }
}
