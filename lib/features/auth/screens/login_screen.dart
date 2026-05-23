import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';
import 'email_auth_screen.dart';

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
        'google' => await AuthService.signInWithGoogle(),
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
    } catch (e) {
      if (!mounted) return;
      _showLoginError(provider);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  void _showLoginError(String provider) {
    final providerName = switch (provider) {
      'kakao' => '카카오',
      'naver' => '네이버',
      'google' => 'Google',
      'apple' => 'Apple',
      _ => '소셜',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.orange, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              '$providerName 연동 준비 중',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'API 키 설정이 필요합니다.\n지금은 테스트 로그인을 이용해주세요.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginAsGuest() async {
    setState(() => _loadingProvider = 'guest');
    await AuthService.signInAsGuest();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                // 로고
                const Text(
                  'PINSPOT',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '찍는 순간, 지도가 된다',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 48),

                // ── 테스트 로그인 (메인 CTA) ────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.08),
                        AppTheme.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BETA TEST',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '바로 체험하기',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '앱 키 설정 없이 모든 기능을 체험해보세요',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loadingProvider != null ? null : _loginAsGuest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            elevation: 0,
                          ),
                          child: _loadingProvider == 'guest'
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.rocket_launch_outlined, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      '테스트로 시작하기',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                // 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: const Color(0xFFE8E8E8))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '소셜 계정으로 시작',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                      ),
                    ),
                    Expanded(child: Divider(color: const Color(0xFFE8E8E8))),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 소셜 로그인 버튼들 ─────────────────────────────────────
                _LoginButton(
                  label: '카카오로 시작하기',
                  backgroundColor: const Color(0xFFFEE500),
                  textColor: const Color(0xFF3C1E1E),
                  icon: const Text('K', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3C1E1E))),
                  loading: _loadingProvider == 'kakao',
                  onTap: () => _login('kakao'),
                ),
                const SizedBox(height: 10),
                _LoginButton(
                  label: '네이버로 시작하기',
                  backgroundColor: const Color(0xFF03C75A),
                  textColor: Colors.white,
                  icon: const Text('N', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  loading: _loadingProvider == 'naver',
                  onTap: () => _login('naver'),
                ),
                const SizedBox(height: 10),
                _LoginButton(
                  label: 'Google로 시작하기',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF1F1F1F),
                  icon: const Text('G', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                  loading: _loadingProvider == 'google',
                  onTap: () => _login('google'),
                  border: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                const SizedBox(height: 10),
                _LoginButton(
                  label: 'Apple로 시작하기',
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  loading: _loadingProvider == 'apple',
                  onTap: () => _login('apple'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('또는',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.6))),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
                  ],
                ),
                const SizedBox(height: 16),
                _LoginButton(
                  label: '이메일로 시작하기',
                  backgroundColor: AppTheme.background,
                  textColor: AppTheme.textPrimary,
                  icon: const Icon(Icons.email_outlined, color: AppTheme.textPrimary, size: 20),
                  loading: false,
                  onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                  border: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의합니다',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;
  final bool loading;
  final VoidCallback onTap;
  final BorderSide? border;

  const _LoginButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        shape: border != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: border!,
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(width: 26, height: 26, child: Center(child: icon)),
                const Spacer(),
                loading
                    ? SizedBox(
                        width: 18, height: 18,
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
                const SizedBox(width: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
