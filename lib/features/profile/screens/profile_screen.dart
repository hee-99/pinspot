import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _ProfileHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _ContentTab(),
            _MyMapTab(),
            _SavedTab(),
          ],
        ),
      ),
    );
  }
}

// ─── 프로필 헤더 ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, size: 44, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '탐험가123',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '@explorer123',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        _StatItem(label: '핀', value: '42'),
                        SizedBox(width: 20),
                        _StatItem(label: '팔로워', value: '1.2K'),
                        SizedBox(width: 20),
                        _StatItem(label: '팔로잉', value: '389'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '숨겨진 조각상을 찾아다니는 도시 탐험가\n서울 구석구석 비밀 명소 발굴 중',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('프로필 편집'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('공유'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─── 탭바 ──────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined, size: 20)),
          Tab(icon: Icon(Icons.map_outlined, size: 20)),
          Tab(icon: Icon(Icons.bookmark_outline, size: 20)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─── 탭 1: 카테고리별 콘텐츠 ───────────────────────────────────────────────────

class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  static const _categories = [
    ('전체', 12),
    ('조각상', 5),
    ('폐허', 2),
    ('사진 명소', 3),
    ('문화재', 1),
    ('등산', 1),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedIndex].$1;
    final count = _categories[_selectedIndex].$2;

    return Column(
      children: [
        _CategoryChips(
          categories: _categories,
          selectedIndex: _selectedIndex,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Text(
                selectedCategory == '전체' ? '전체' : selectedCategory,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(
                '$count개',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: count,
            itemBuilder: (context, index) => _PinThumbnail(
              category: selectedCategory == '전체'
                  ? _categories[(index % (_categories.length - 1)) + 1].$1
                  : selectedCategory,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<(String, int)> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(categories.length, (i) {
            final isSelected = i == selectedIndex;
            final (label, count) = categories[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Text(
                    '$label  $count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PinThumbnail extends StatelessWidget {
  final String category;

  const _PinThumbnail({required this.category});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.grey[200]),
        const Center(child: Icon(Icons.image_outlined, size: 32, color: AppTheme.textSecondary)),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 탭 2: 나의 지도 ───────────────────────────────────────────────────────────

class _PinData {
  final String name;
  final String category;
  final LatLng position;

  const _PinData(this.name, this.category, this.position);
}

class _MyMapTab extends StatefulWidget {
  const _MyMapTab();

  @override
  State<_MyMapTab> createState() => _MyMapTabState();
}

class _MyMapTabState extends State<_MyMapTab> {
  final Completer<GoogleMapController> _controller = Completer();

  static const _pins = [
    _PinData('서울 종로구 조각상', '조각상', LatLng(37.5745, 126.9768)),
    _PinData('성수동 폐공장', '폐허', LatLng(37.5443, 127.0557)),
    _PinData('북한산 뷰포인트', '등산', LatLng(37.6176, 127.0060)),
    _PinData('낙산공원 야경', '사진 명소', LatLng(37.5798, 127.0018)),
    _PinData('경복궁 옆 골목', '문화재', LatLng(37.5796, 126.9770)),
    _PinData('한강 일몰 스팟', '사진 명소', LatLng(37.5219, 126.9394)),
    _PinData('서울숲 비밀길', '등산', LatLng(37.5443, 127.0386)),
  ];

  Set<Marker> get _markers => _pins.map((pin) => Marker(
    markerId: MarkerId(pin.name),
    position: pin.position,
    infoWindow: InfoWindow(title: pin.name, snippet: pin.category),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  )).toSet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.5665, 126.9780),
                  zoom: 11.5,
                ),
                onMapCreated: (c) => _controller.complete(c),
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              // 핀 개수 배지
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text('내 핀 ${_pins.length}개', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 핀 목록
        Container(
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text('방문한 장소', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _pins.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => _PlaceChip(pin: _pins[index]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _PlaceChip extends StatelessWidget {
  final _PinData pin;

  const _PlaceChip({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pin.category,
              style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pin.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── 탭 3: 저장됨 ──────────────────────────────────────────────────────────────

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  static const _savedItems = [
    ('을지로 벽화골목', '사진 명소'),
    ('인왕산 일출', '등산'),
    ('창신동 절벽마을', '폐허'),
    ('광장시장 야경', '사진 명소'),
    ('서울로 7017', '산책'),
    ('낙산성곽 뷰', '문화재'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _savedItems.length,
      itemBuilder: (context, index) {
        final (name, category) = _savedItems[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.grey[200]),
            const Center(child: Icon(Icons.image_outlined, size: 32, color: AppTheme.textSecondary)),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark, size: 14, color: AppTheme.primary),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
