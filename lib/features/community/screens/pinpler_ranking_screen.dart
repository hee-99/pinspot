import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'pinpler_profile_screen.dart';
import 'pinpler_combined_map_screen.dart';

// ─── 더미 데이터 ────────────────────────────────────────────────────────────────

class PinplerData {
  final String name;
  final String handle;
  final int pinCount;
  final int likes;
  final int saves;
  final Color avatarColor;
  final List<PinLocation> pins;

  const PinplerData({
    required this.name,
    required this.handle,
    required this.pinCount,
    required this.likes,
    required this.saves,
    required this.avatarColor,
    required this.pins,
  });
}

class PinLocation {
  final String name;
  final String category;
  final double lat;
  final double lng;

  const PinLocation(this.name, this.category, this.lat, this.lng);
}

const _samplePinplers = [
  PinplerData(
    name: '산악대장',
    handle: '@mountainking',
    pinCount: 128,
    likes: 9420,
    saves: 3210,
    avatarColor: Color(0xFF4CAF50),
    pins: [
      PinLocation('북한산 정상', '등산/명산', 37.6580, 126.9780),
      PinLocation('도봉산 비경', '등산/명산', 37.7020, 127.0230),
      PinLocation('관악산 야경', '등산/명산', 37.4443, 126.9640),
      PinLocation('청계산 뷰', '등산/명산', 37.4200, 127.0560),
    ],
  ),
  PinplerData(
    name: '트레일러버',
    handle: '@traillover',
    pinCount: 97,
    likes: 7830,
    saves: 2890,
    avatarColor: Color(0xFF2196F3),
    pins: [
      PinLocation('수락산 철모바위', '등산/명산', 37.6680, 127.0760),
      PinLocation('불암산 정상', '등산/명산', 37.6500, 127.1010),
      PinLocation('아차산 고구려', '등산/명산', 37.5640, 127.1050),
    ],
  ),
  PinplerData(
    name: '서울탐험대',
    handle: '@seoulexplorer',
    pinCount: 84,
    likes: 6120,
    saves: 2340,
    avatarColor: Color(0xFFFF9800),
    pins: [
      PinLocation('인왕산 일출', '등산/명산', 37.5840, 126.9570),
      PinLocation('안산 성곽길', '등산/명산', 37.5960, 126.9390),
      PinLocation('남산 타워뷰', '등산/명산', 37.5512, 126.9882),
    ],
  ),
  PinplerData(
    name: '피크헌터',
    handle: '@peakhunter',
    pinCount: 71,
    likes: 5430,
    saves: 1980,
    avatarColor: Color(0xFFE91E63),
    pins: [
      PinLocation('용마산 능선', '등산/명산', 37.5740, 127.0920),
      PinLocation('망우산 정상', '등산/명산', 37.5880, 127.0990),
    ],
  ),
  PinplerData(
    name: '새벽산행러',
    handle: '@dawnhiker',
    pinCount: 63,
    likes: 4780,
    saves: 1650,
    avatarColor: Color(0xFF9C27B0),
    pins: [
      PinLocation('수리산 일출', '등산/명산', 37.3680, 126.8840),
      PinLocation('광교산 정상', '등산/명산', 37.2790, 127.0430),
    ],
  ),
];

// ─── 랭킹 화면 ─────────────────────────────────────────────────────────────────

enum _SortType { pins, likes, saves }

class PinplerRankingScreen extends StatefulWidget {
  final String category;
  final IconData categoryIcon;
  final Color categoryColor;

  const PinplerRankingScreen({
    super.key,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<PinplerRankingScreen> createState() => _PinplerRankingScreenState();
}

class _PinplerRankingScreenState extends State<PinplerRankingScreen> {
  _SortType _sortType = _SortType.likes;
  bool _isSelectMode = false;
  final Set<int> _selected = {};

  List<PinplerData> get _sorted {
    final list = List<PinplerData>.from(_samplePinplers);
    switch (_sortType) {
      case _SortType.pins:
        list.sort((a, b) => b.pinCount.compareTo(a.pinCount));
      case _SortType.likes:
        list.sort((a, b) => b.likes.compareTo(a.likes));
      case _SortType.saves:
        list.sort((a, b) => b.saves.compareTo(a.saves));
    }
    return list;
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selected.clear();
    });
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _openCombinedMap() {
    final sorted = _sorted;
    final pinplers = _selected.map((i) => sorted[i]).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinplerCombinedMapScreen(
          pinplers: pinplers,
          category: widget.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.categoryIcon, size: 18, color: widget.categoryColor),
            const SizedBox(width: 8),
            Text(widget.category, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _toggleSelectMode,
            child: Text(
              _isSelectMode ? '취소' : '선택',
              style: TextStyle(
                color: _isSelectMode ? Colors.red : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SortBar(
            selected: _sortType,
            onSelect: (t) => setState(() => _sortType = t),
          ),
          if (_isSelectMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withValues(alpha: 0.07),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '핀플을 선택해 지도에서 함께 보세요',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final pinpler = sorted[index];
                final isSelected = _selected.contains(index);
                return _PinplerCard(
                  rank: index + 1,
                  pinpler: pinpler,
                  categoryColor: widget.categoryColor,
                  isSelectMode: _isSelectMode,
                  isSelected: isSelected,
                  onTap: () {
                    if (_isSelectMode) {
                      _toggleSelect(index);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinplerProfileScreen(
                            pinpler: pinpler,
                            category: widget.category,
                            categoryColor: widget.categoryColor,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectMode && _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCombinedMap,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              label: Text(
                '${_selected.length}명 지도 보기',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}

// ─── 정렬 바 ──────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final _SortType selected;
  final ValueChanged<_SortType> onSelect;

  const _SortBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('정렬', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(width: 10),
          _SortChip(
            label: '좋아요순',
            icon: Icons.favorite_outline,
            isSelected: selected == _SortType.likes,
            onTap: () => onSelect(_SortType.likes),
          ),
          const SizedBox(width: 6),
          _SortChip(
            label: '핀 많은순',
            icon: Icons.location_on_outlined,
            isSelected: selected == _SortType.pins,
            onTap: () => onSelect(_SortType.pins),
          ),
          const SizedBox(width: 6),
          _SortChip(
            label: '저장순',
            icon: Icons.bookmark_outline,
            isSelected: selected == _SortType.saves,
            onTap: () => onSelect(_SortType.saves),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 핀플 카드 ────────────────────────────────────────────────────────────────

class _PinplerCard extends StatelessWidget {
  final int rank;
  final PinplerData pinpler;
  final Color categoryColor;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;

  const _PinplerCard({
    required this.rank,
    required this.pinpler,
    required this.categoryColor,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.06) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // 랭크
            SizedBox(
              width: 28,
              child: Text(
                rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
                style: TextStyle(
                  fontSize: rank <= 3 ? 18 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // 아바타
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: pinpler.avatarColor,
                  child: Text(
                    pinpler.name[0],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (isSelectMode)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : const Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 이름/핸들
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pinpler.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '핀플',
                          style: TextStyle(fontSize: 9, color: categoryColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pinpler.handle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatBadge(icon: Icons.location_on_outlined, value: '${pinpler.pinCount}', color: AppTheme.primary),
                      const SizedBox(width: 10),
                      _StatBadge(icon: Icons.favorite_outline, value: _formatNum(pinpler.likes), color: Colors.redAccent),
                      const SizedBox(width: 10),
                      _StatBadge(icon: Icons.bookmark_outline, value: _formatNum(pinpler.saves), color: Colors.amber[700]!),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelectMode)
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatNum(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
