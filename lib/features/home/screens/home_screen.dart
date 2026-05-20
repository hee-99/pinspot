import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
  int _currentIndex = 1;

  static const _screens = [
    FeedScreen(),
    MapScreen(),
    SizedBox.shrink(), // 가운데 핀 추가 버튼 자리 (탭 전환 없음)
    CommunityScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return; // 가운데 버튼은 FAB으로 처리
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _PinFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _PinFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePinScreen()),
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.27), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.add_location_alt, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppTheme.surface,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: '피드', index: 0, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: '지도', index: 1, currentIndex: currentIndex, onTap: onTap),
            const SizedBox(width: 58), // FAB 자리
            _NavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: '커뮤니티', index: 3, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '프로필', index: 4, currentIndex: currentIndex, onTap: onTap),
          ],
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
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

