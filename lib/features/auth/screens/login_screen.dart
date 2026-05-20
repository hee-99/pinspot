import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              _SocialLoginButton(
                label: '카카오로 시작하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF3C1E1E),
                onTap: () => _goHome(context),
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                label: '네이버로 시작하기',
                backgroundColor: const Color(0xFF03C75A),
                textColor: Colors.white,
                onTap: () => _goHome(context),
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                label: 'Google로 시작하기',
                backgroundColor: Colors.white,
                textColor: AppTheme.textPrimary,
                borderColor: const Color(0xFFDDDDDD),
                onTap: () => _goHome(context),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
