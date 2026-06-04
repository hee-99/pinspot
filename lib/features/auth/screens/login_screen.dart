import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../home/screens/home_screen.dart';
import 'email_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String? _loadingProvider;

  late final AnimationController _cardCtrl;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  static const _kDark = AppColors.darkBg;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _cardCtrl.forward());
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

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
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else if (provider == 'apple') {
        _snack(AppLocalizations.of(context).startWithApple);
      }
    } catch (_) {
      if (!mounted) return;
      _showLoginError(provider);
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  void _showLoginError(String provider) {
    final l = AppLocalizations.of(context);
    final name = switch (provider) {
      'kakao'  => 'Kakao',
      'naver'  => 'Naver',
      'google' => 'Google',
      'apple'  => 'Apple',
      _        => provider,
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings_outlined, color: AppColors.warning, size: 28),
            ),
            const SizedBox(height: 16),
            Text(l.providerSetupTitle(name),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.neutral900),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(l.providerSetupDesc,
                style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.6),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(l.confirm)),
          ),
        ],
      ),
    );
  }

  Future<void> _loginAsGuest() async {
    setState(() => _loadingProvider = 'guest');
    await AuthService.signInAsGuest();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool get _busy => _loadingProvider != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final heroH = mq.size.height * 0.37;

    return Scaffold(
      backgroundColor: _kDark,
      body: Column(
        children: [
          // ── 히어로 영역 ─────────────────────────────────────────────────
          SizedBox(
            height: heroH,
            child: _HeroSection(topPad: mq.padding.top),
          ),

          // ── 로그인 카드 (슬라이드업) ────────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3EE),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 게스트 체험 버튼
                          _BetaCard(
                            loading: _loadingProvider == 'guest',
                            onTap: _busy ? null : _loginAsGuest,
                            l: l,
                          ),

                          const SizedBox(height: 22),
                          _DividerRow(label: l.startWithSocial),
                          const SizedBox(height: 16),

                          // 카카오
                          _SocialBtn(
                            label: l.startWithKakao,
                            bg: const Color(0xFFFEE500),
                            fg: const Color(0xFF3C1E1E),
                            icon: const Text('K', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3C1E1E))),
                            loading: _loadingProvider == 'kakao',
                            onTap: _busy ? null : () => _login('kakao'),
                          ),
                          const SizedBox(height: 10),

                          // 네이버
                          _SocialBtn(
                            label: l.startWithNaver,
                            bg: const Color(0xFF03C75A),
                            fg: Colors.white,
                            icon: const Text('N', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            loading: _loadingProvider == 'naver',
                            onTap: _busy ? null : () => _login('naver'),
                          ),
                          const SizedBox(height: 10),

                          // 구글
                          _SocialBtn(
                            label: l.startWithGoogle,
                            bg: Colors.white,
                            fg: const Color(0xFF1F1F1F),
                            icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                            loading: _loadingProvider == 'google',
                            onTap: _busy ? null : () => _login('google'),
                            border: const BorderSide(color: AppColors.neutral200),
                          ),
                          const SizedBox(height: 10),

                          // 애플
                          _SocialBtn(
                            label: l.startWithApple,
                            bg: AppColors.neutral900,
                            fg: Colors.white,
                            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                            loading: _loadingProvider == 'apple',
                            onTap: _busy ? null : () => _login('apple'),
                          ),

                          const SizedBox(height: 16),
                          _DividerRow(label: l.or),
                          const SizedBox(height: 16),

                          // 이메일
                          _SocialBtn(
                            label: l.startWithEmail,
                            bg: const Color(0xFFEEECE7),
                            fg: const Color(0xFF1C1C1E),
                            icon: const Icon(Icons.mail_outline_rounded, color: AppColors.neutral600, size: 20),
                            loading: false,
                            onTap: _busy
                                ? null
                                : () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                          ),

                          const SizedBox(height: 20),
                          Text(
                            l.loginTerms,
                            style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 히어로 섹션 ────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final double topPad;
  const _HeroSection({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _HeroBgPainter()),
        Padding(
          padding: EdgeInsets.only(top: topPad + 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 핀 아이콘
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 32, offset: const Offset(0, 8)),
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 64, offset: const Offset(0, 20)),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 18),
              const Text(
                'PINSPOT',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '찍는 순간, 기록이 된다',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 다크 포레스트 그라디언트
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
    final center = Offset(size.width / 2, size.height * 0.50);
    canvas.drawCircle(
      center,
      size.width * 0.52,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.primary.withValues(alpha: 0.13),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: center, radius: size.width * 0.52)),
    );

    // 흩어진 핀 도트
    final dotPaint = Paint();
    for (final d in [
      [0.08, 0.14, 2.5, 0.20],
      [0.91, 0.09, 2.0, 0.16],
      [0.83, 0.72, 2.5, 0.14],
      [0.14, 0.82, 2.0, 0.13],
      [0.95, 0.56, 1.5, 0.12],
      [0.45, 0.05, 2.5, 0.18],
      [0.03, 0.47, 1.5, 0.13],
      [0.66, 0.89, 2.0, 0.11],
      [0.59, 0.19, 1.5, 0.14],
      [0.29, 0.63, 2.0, 0.10],
    ]) {
      dotPaint.color = AppColors.primary.withValues(alpha: d[3]);
      canvas.drawCircle(Offset(size.width * d[0], size.height * d[1]), d[2], dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ── BETA 체험 카드 ──────────────────────────────────────────────────────────────
class _BetaCard extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  final AppLocalizations l;
  const _BetaCard({required this.loading, required this.onTap, required this.l});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(l.betaTest,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 5),
                    Text(l.tryNow,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(l.tryNowDesc,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.72))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소셜 로그인 버튼 ────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final Widget icon;
  final bool loading;
  final VoidCallback? onTap;
  final BorderSide? border;

  const _SocialBtn({
    required this.label, required this.bg, required this.fg,
    required this.icon, required this.loading, required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border ?? BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(width: 24, child: Center(child: icon)),
                const Spacer(),
                loading
                    ? SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg.withValues(alpha: 0.6)))
                    : Text(label,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
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

// ── 구분선 ─────────────────────────────────────────────────────────────────────
class _DividerRow extends StatelessWidget {
  final String label;
  const _DividerRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.neutral200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
        ),
        const Expanded(child: Divider(color: AppColors.neutral200)),
      ],
    );
  }
}
