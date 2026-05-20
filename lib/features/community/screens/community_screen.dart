import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'pinpler_ranking_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const _categories = [
    ('등산/명산', Icons.terrain_outlined, Color(0xFF4CAF50)),
    ('조각상/공공예술', Icons.account_balance_outlined, Color(0xFF9C27B0)),
    ('계곡/자연', Icons.water_outlined, Color(0xFF2196F3)),
    ('폐허/어반', Icons.domain_disabled_outlined, Color(0xFF795548)),
    ('사진 명소', Icons.camera_alt_outlined, Color(0xFFFF9800)),
    ('공포 명소', Icons.nightlife_outlined, Color(0xFF607D8B)),
    ('영화 성지', Icons.movie_outlined, Color(0xFFE91E63)),
    ('음식 마니아', Icons.restaurant_outlined, Color(0xFFFF5722)),
    ('문화재/역사', Icons.museum_outlined, Color(0xFF3F51B5)),
    ('숙소 큐레이터', Icons.hotel_outlined, Color(0xFF00BCD4)),
    ('자연 치유', Icons.spa_outlined, Color(0xFF8BC34A)),
    ('익스트림', Icons.paragliding_outlined, Color(0xFFF44336)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '커뮤니티',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.pin_drop, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                const Text(
                  '핀플',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '— 카테고리별 핀 인플루언서를 만나보세요',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final (label, icon, color) = _categories[index];
          return _CategoryCard(
            label: label,
            icon: icon,
            color: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PinplerRankingScreen(
                    category: label,
                    categoryIcon: icon,
                    categoryColor: color,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '핀플 보기',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
