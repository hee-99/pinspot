import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/core/l10n/app_localizations.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/features/map/screens/map_screen.dart';
import 'package:pinspot/features/community/screens/community_screen.dart';
import 'package:pinspot/account/profile/screens/profile_screen.dart';
import 'package:pinspot/features/tigo/services/tigo_service.dart';
import 'package:pinspot/features/tigo/widgets/tigo_unlock_dialog.dart';

// 앱의 메인 셸 화면 — 3탭 바텀 네비게이션과 IndexedStack으로 탭별 화면 전환 관리
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0: 지도, 1: 커뮤니티, 2: 프로필 (핀 등록은 지도 화면 안의 카메라 버튼으로 이동)
  int _currentIndex = 0; // 기본: 지도

  // 첫 방문 시에만 실제 위젯을 빌드 (lazy init)
  final Set<int> _builtIndices = {0};

  @override
  void initState() {
    super.initState();
    _checkPrivacyNotice();
    TigoService.instance.addListener(_onTigoUpdate);
  }

  // 티고 아이템 새로 잠금 해제 시 다이얼로그 표시
  void _onTigoUpdate() {
    final newItems = TigoService.instance.consumePendingUnlock();
    if (newItems.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => TigoUnlockDialog(items: newItems),
          );
        }
      });
    }
  }

  // 개인정보 동의 여부를 확인하고 미동의 시 안내 시트 표시
  Future<void> _checkPrivacyNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('privacy_accepted') ?? false;
    if (!accepted && mounted) {
      // 지도·초기 UI가 완전히 렌더된 후 시트 표시
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _showPrivacyNotice();
    }
  }

  // 개인정보 동의 바텀시트를 모달로 표시 (닫기/드래그 불가, 동의해야 닫힘)
  void _showPrivacyNotice() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrivacyNoticeSheet(
        onAccept: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('privacy_accepted', true);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    TigoService.instance.removeListener(_onTigoUpdate);
    super.dispose();
  }

  // 바텀 네비 탭 클릭 처리 — IndexedStack 전환
  void _onTabTapped(int index) {
    setState(() {
      _builtIndices.add(index); // 첫 방문 시 위젯 빌드 트리거
      _currentIndex = index;
    });
  }

  // 탭별 화면을 IndexedStack으로 쌓아 상태 유지하며 전환
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MapScreen(),
          _builtIndices.contains(1) ? const CommunityScreen() : const SizedBox.shrink(),
          _builtIndices.contains(2) ? const ProfileScreen()   : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Bottom Navigation (3탭: 지도·커뮤니티·프로필, 핀 등록은 지도 화면 내 카메라 버튼으로) ──
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.map_outlined,        activeIcon: Icons.map,        label: '지도',    index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.people_outline,      activeIcon: Icons.people,     label: '커뮤니티', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline,      activeIcon: Icons.person,     label: '프로필',  index: 2, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

// 바텀 네비 개별 탭 아이템 — 활성/비활성 아이콘·색상 전환
class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

  static const _orange   = Color(0xFFFF8A00);
  static const _inactive = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    final active = current == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(active ? activeIcon : icon,
                  key: ValueKey(active),
                  color: active ? _orange : _inactive,
                  size: 24),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? _orange : _inactive,
                )),
          ],
        ),
      ),
    );
  }
}

// ── 개인정보 동의 시트 ─────────────────────────────────────────────────────────
class _PrivacyNoticeSheet extends StatelessWidget {
  final VoidCallback onAccept;
  const _PrivacyNoticeSheet({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
            )),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(l.privacyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
            ]),
            const SizedBox(height: 16),
            Text(l.privacyContent, style: const TextStyle(fontSize: 13, height: 1.75, color: AppColors.neutral600)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: onAccept,
                child: Text(l.privacyAccept, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
