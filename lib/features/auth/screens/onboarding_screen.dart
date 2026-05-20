import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _privacyAgreed = false;
  bool _locationAgreed = false;
  bool _galleryAgreed = false;
  bool _isLoading = false;

  bool get _canProceed => _privacyAgreed && _locationAgreed && _galleryAgreed;

  Future<void> _proceed() async {
    if (!_canProceed || _isLoading) return;
    setState(() => _isLoading = true);

    // 웹에서는 브라우저 자체 권한 팝업 사용 (permission_handler 미지원)
    if (!kIsWeb) {
      if (_locationAgreed) {
        await Permission.locationWhenInUse.request();
      }
      if (_galleryAgreed) {
        await Permission.camera.request();
        await Permission.photos.request();
      }
    }

    // 온보딩 완료 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              const SizedBox(height: 48),
              // 헤더
              const Icon(Icons.location_on, color: AppTheme.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'PINSPOT 시작 전\n동의가 필요해요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3),
              ),
              const SizedBox(height: 8),
              const Text(
                '서비스 이용을 위해 아래 항목에 동의해 주세요.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              // 전체 동의
              _AllAgreeRow(
                agreed: _privacyAgreed && _locationAgreed && _galleryAgreed,
                onTap: () {
                  final all = _privacyAgreed && _locationAgreed && _galleryAgreed;
                  setState(() {
                    _privacyAgreed = !all;
                    _locationAgreed = !all;
                    _galleryAgreed = !all;
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),

              // 개별 동의 항목
              _AgreementItem(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침 동의',
                subtitle: '수집된 정보는 서비스 제공 목적으로만 사용됩니다',
                required: true,
                agreed: _privacyAgreed,
                onTap: () => setState(() => _privacyAgreed = !_privacyAgreed),
                onDetailTap: () => _showDetail(context, '개인정보처리방침',
                    'PINSPOT은 서비스 제공을 위해 최소한의 개인정보를 수집합니다.\n\n'
                    '• 수집 항목: 이름, 이메일, 위치정보\n'
                    '• 이용 목적: 서비스 제공, 핀 등록 및 조회\n'
                    '• 보유 기간: 회원 탈퇴 시까지\n\n'
                    '위 내용에 동의하시면 서비스를 이용하실 수 있습니다.'),
              ),
              const SizedBox(height: 12),
              _AgreementItem(
                icon: Icons.location_on_outlined,
                title: '위치 정보 수집·이용 동의',
                subtitle: '핀 등록 및 주변 장소 탐색에 사용됩니다',
                required: true,
                agreed: _locationAgreed,
                onTap: () => setState(() => _locationAgreed = !_locationAgreed),
                onDetailTap: () => _showDetail(context, '위치 정보 수집·이용 동의',
                    'PINSPOT은 아래 목적으로 위치 정보를 수집합니다.\n\n'
                    '• 핀 등록 시 현재 위치 확인\n'
                    '• 사진 촬영 장소와 현재 위치 일치 여부 검증\n'
                    '• 주변 핀 및 핀플 탐색\n\n'
                    '위치 정보는 핀 등록 시에만 사용되며 별도로 저장되지 않습니다.'),
              ),
              const SizedBox(height: 12),
              _AgreementItem(
                icon: Icons.photo_library_outlined,
                title: '카메라 및 갤러리 접근 동의',
                subtitle: '핀 사진 촬영 및 갤러리에서 사진을 불러옵니다',
                required: true,
                agreed: _galleryAgreed,
                onTap: () => setState(() => _galleryAgreed = !_galleryAgreed),
                onDetailTap: () => _showDetail(context, '카메라 및 갤러리 접근 동의',
                    'PINSPOT은 핀 등록을 위해 아래 권한이 필요합니다.\n\n'
                    '• 카메라: 현재 위치에서 사진 직접 촬영\n'
                    '• 갤러리: GPS 정보가 포함된 사진 불러오기\n\n'
                    '⚠️ 중요: 갤러리 사진은 촬영 장소와 현재 위치가\n'
                    '일치하는 경우에만 핀 등록이 가능합니다.'),
              ),

              const Spacer(),

              // 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canProceed ? _proceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'PINSPOT 시작하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.7)),
          ],
        ),
      ),
    );
  }
}

class _AllAgreeRow extends StatelessWidget {
  final bool agreed;
  final VoidCallback onTap;

  const _AllAgreeRow({required this.agreed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: agreed ? AppTheme.primary : Colors.transparent,
              border: Border.all(color: agreed ? AppTheme.primary : const Color(0xFFCCCCCC), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: agreed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          const Text('전체 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AgreementItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool required;
  final bool agreed;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;

  const _AgreementItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.required,
    required this.agreed,
    required this.onTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: agreed ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: agreed ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: agreed ? AppTheme.primary : Colors.transparent,
                border: Border.all(color: agreed ? AppTheme.primary : const Color(0xFFCCCCCC), width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (required)
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('필수', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      Flexible(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDetailTap,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
