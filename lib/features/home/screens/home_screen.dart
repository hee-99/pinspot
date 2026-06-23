import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../map/screens/map_screen.dart';
import '../../community/screens/community_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../pin/screens/create_pin_screen.dart';
import '../../tigo/services/tigo_service.dart';
import '../../tigo/widgets/tigo_unlock_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0: 카메라(modal), 1: 지도, 2: 커뮤니티, 3: 프로필
  int _currentIndex = 1; // 기본: 지도

  static const _screens = [
    SizedBox.shrink(),  // 0: 카메라 → modal
    MapScreen(),        // 1: 지도
    CommunityScreen(),  // 2: 커뮤니티
    ProfileScreen(),    // 3: 프로필
  ];

  @override
  void initState() {
    super.initState();
    _checkPrivacyNotice();
    TigoService.instance.addListener(_onTigoUpdate);
  }

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

  Future<void> _checkPrivacyNotice() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('privacy_accepted') ?? false;
    if (!accepted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyNotice());
    }
  }

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

  void _onTabTapped(int index) {
    if (index == 0) {
      // 카메라: 모달로 열기, 현재 탭 유지
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreatePinScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Bottom Navigation (4탭: 카메라·지도·커뮤니티·프로필) ──────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _orange   = Color(0xFFFF8A00);
  static const _inactive = Color(0xFFAAAAAA);

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
              // 카메라 탭 (특별 스타일 — 항상 orange circle)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _orange.withValues(alpha: 0.40), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(icon: Icons.map_outlined,        activeIcon: Icons.map,        label: '지도',    index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.people_outline,      activeIcon: Icons.people,     label: '커뮤니티', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline,      activeIcon: Icons.person,     label: '프로필',  index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

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
