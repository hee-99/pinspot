import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../feed/screens/feed_screen.dart';
import '../../map/screens/map_screen.dart';
import '../../community/screens/community_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../pin/screens/create_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // 기본: 지도

  static const _screens = [
    FeedScreen(),
    MapScreen(),
    SizedBox.shrink(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPrivacyNotice();
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

  void _onTabTapped(int index) {
    if (index == 2) {
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
      backgroundColor: AppColors.neutral50,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.neutral200, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.explore_outlined,  activeIcon: Icons.explore,  label: l.navFeed,      index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.map_outlined,       activeIcon: Icons.map,      label: l.navMap,       index: 1, current: currentIndex, onTap: onTap),
              // 중앙 핀 버튼
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_location_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.navPin,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(icon: Icons.groups_outlined,  activeIcon: Icons.groups,  label: l.navCommunity, index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline,   activeIcon: Icons.person,  label: l.navProfile,   index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

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
            // 액티브 인디케이터 (상단 점)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 18 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                active ? activeIcon : icon,
                key: ValueKey(active),
                color: active ? AppColors.primary : AppColors.neutral400,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.neutral400,
              ),
            ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(l.privacyTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.privacyContent,
              style: const TextStyle(fontSize: 13, height: 1.75, color: AppColors.neutral600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: onAccept,
                child: Text(l.privacyAccept,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
