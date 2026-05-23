import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/utils/marker_builder.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  UserModel? _user;
  List<PinModel> _pins = [];
  bool _loading = true;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
    _loadMapStyle();
    PinRefreshNotifier.instance.addListener(_load);
  }

  @override
  void dispose() {
    _tabController.dispose();
    PinRefreshNotifier.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = await AuthService.getUser();
    final pins = await PinService.getPins();
    if (mounted) setState(() { _user = user; _pins = pins; _loading = false; });
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('로그아웃', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    String? newPhotoPath = _user?.localPhotoPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
                ),
                const Text('프로필 편집', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
                    if (file != null) setSheetState(() => newPhotoPath = file.path);
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primary,
                        backgroundImage: newPhotoPath != null && !kIsWeb
                            ? FileImage(File(newPhotoPath!)) : null,
                        child: (newPhotoPath == null || kIsWeb)
                            ? (_user?.photoUrl != null
                                ? null
                                : const Icon(Icons.person, size: 48, color: Colors.white))
                            : null,
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    hintText: '새 닉네임을 입력하세요',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await AuthService.updateProfile(
                        name: nameCtrl.text.trim().isEmpty ? (_user?.name ?? '') : nameCtrl.text.trim(),
                        localPhotoPath: newPhotoPath,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (updated != null && mounted) setState(() => _user = updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SettingsItem(
              icon: Icons.person_outline,
              label: '프로필 편집',
              onTap: () => Navigator.pop(context),
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              label: '알림 설정',
              onTap: () => Navigator.pop(context),
            ),
            _SettingsItem(
              icon: Icons.lock_outline,
              label: '개인정보 설정',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _SettingsItem(
              icon: Icons.logout,
              label: '로그아웃',
              color: const Color(0xFFC62828),
              onTap: () { Navigator.pop(context); _logout(); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          _user?.name ?? '프로필',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: _user, pinCount: _pins.length),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ContentTab(pins: _pins),
            _MyMapTab(pins: _pins, mapStyle: _mapStyle),
            _SavedTab(pins: _pins),
          ],
        ),
      ),
    );
  }
}

// ─── 설정 아이템 ──────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: c)),
      trailing: Icon(Icons.chevron_right, color: c.withValues(alpha: 0.4), size: 20),
      onTap: onTap,
    );
  }
}

// ─── 프로필 헤더 ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final int pinCount;

  const _ProfileHeader({required this.user, required this.pinCount});

  @override
  Widget build(BuildContext context) {
    final providerLabel = switch (user?.provider) {
      'kakao'  => '카카오',
      'naver'  => '네이버',
      'google' => 'Google',
      'apple'  => 'Apple',
      'email'  => '이메일',
      _        => null,
    };

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildAvatar(),
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
                        Flexible(
                          child: Text(
                            user?.name ?? '탐험가',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (providerLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              providerLabel,
                              style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        user!.email!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatItem(label: '핀', value: '$pinCount'),
                        const SizedBox(width: 20),
                        const _StatItem(label: '팔로워', value: '0'),
                        const SizedBox(width: 20),
                        const _StatItem(label: '팔로잉', value: '0'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final state = context.findAncestorStateOfType<_ProfileScreenState>();
                    await state?._editProfile();
                  },
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

  Widget _buildAvatar() {
    if (user?.localPhotoPath != null && !kIsWeb) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: FileImage(File(user!.localPhotoPath!)),
        backgroundColor: AppTheme.primary,
        onBackgroundImageError: (_, __) {},
      );
    }
    if (user?.photoUrl != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(user!.photoUrl!),
        backgroundColor: AppTheme.primary,
      );
    }
    return const CircleAvatar(
      radius: 44,
      backgroundColor: AppTheme.primary,
      child: Icon(Icons.person, size: 44, color: Colors.white),
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
  const _TabBarDelegate({required this.tabController});

  @override double get minExtent => 48;
  @override double get maxExtent => 48;

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
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─── 탭 1: 내 핀 그리드 ──────────────────────────────────────────────────────

class _ContentTab extends StatefulWidget {
  final List<PinModel> pins;
  const _ContentTab({required this.pins});

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  String _selectedCategory = '전체';

  List<String> get _categories {
    final cats = widget.pins.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<PinModel> get _filtered {
    if (_selectedCategory == '전체') return widget.pins;
    return widget.pins.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('아직 등록한 핀이 없어요\n+ 버튼을 눌러 첫 핀을 등록해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          ],
        ),
      );
    }

    final allCategories = ['전체', ..._categories];

    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: allCategories.map((cat) {
                final isSelected = cat == _selectedCategory;
                final count = cat == '전체'
                    ? widget.pins.length
                    : widget.pins.where((p) => p.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                        '$cat  $count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length}개',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
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
            itemCount: _filtered.length,
            itemBuilder: (context, index) => _PinThumbnail(pin: _filtered[index]),
          ),
        ),
      ],
    );
  }
}

class _PinThumbnail extends StatelessWidget {
  final PinModel pin;
  const _PinThumbnail({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPhoto(),
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
              pin.category,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoto() {
    if (pin.photoPath != null && !kIsWeb) {
      return Image.file(
        File(pin.photoPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.location_on, size: 28, color: AppTheme.primary),
      ),
    );
  }
}

// ─── 탭 2: 나의 지도 ───────────────────────────────────────────────────────────

class _MyMapTab extends StatefulWidget {
  final List<PinModel> pins;
  final String? mapStyle;
  const _MyMapTab({required this.pins, required this.mapStyle});

  @override
  State<_MyMapTab> createState() => _MyMapTabState();
}

class _MyMapTabState extends State<_MyMapTab> {
  final _controller = Completer<GoogleMapController>();
  String _selectedCategory = '전체';
  Map<String, BitmapDescriptor> _markerIcons = {};

  List<String> get _categories {
    final cats = widget.pins.map((p) => p.category).toSet().toList()..sort();
    return ['전체', ...cats];
  }

  List<PinModel> get _filtered {
    if (_selectedCategory == '전체') return widget.pins;
    return widget.pins.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(_MyMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pins.length != oldWidget.pins.length && _controller.isCompleted) {
      _fitBounds();
    }
    if (widget.pins != oldWidget.pins) _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final icons = <String, BitmapDescriptor>{};
    for (final pin in widget.pins) {
      if (pin.photoPath != null) {
        icons[pin.id] = await MarkerBuilder.buildPhotoMarker(pin.photoPath!);
      }
    }
    if (mounted) setState(() => _markerIcons = icons);
  }

  Future<void> _fitBounds() async {
    final pins = _filtered;
    if (pins.isEmpty) return;
    final ctrl = await _controller.future;
    if (pins.length == 1) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pins.first.lat, pins.first.lng), 13));
      return;
    }
    double s = pins.first.lat, n = pins.first.lat;
    double w = pins.first.lng, e = pins.first.lng;
    for (final p in pins) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 80));
  }

  Set<Marker> _buildMarkers(List<PinModel> pins) => pins.map((pin) => Marker(
    markerId: MarkerId(pin.id),
    position: LatLng(pin.lat, pin.lng),
    infoWindow: InfoWindow(title: pin.title, snippet: pin.category),
    icon: _markerIcons[pin.id] ?? BitmapDescriptor.defaultMarkerWithHue(14.0),
  )).toSet();

  LatLng get _defaultCenter {
    final pins = _filtered.isNotEmpty ? _filtered : widget.pins;
    if (pins.isEmpty) return const LatLng(37.5665, 126.9780);
    return LatLng(
      pins.map((p) => p.lat).reduce((a, b) => a + b) / pins.length,
      pins.map((p) => p.lng).reduce((a, b) => a + b) / pins.length,
    );
  }

  void _onCategorySelected(String cat) {
    setState(() => _selectedCategory = cat);
    if (_controller.isCompleted) _fitBounds();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // 카테고리 칩 bar 높이 (padding 10*2 + 칩 27 = 47)
    const filterBarHeight = 47.0;
    // 하단 장소 패널 높이 (레이블 14+14+8 + ListView 80 = 116)
    const placeChipsHeight = 116.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Stack 전략: GoogleMap이 전체 공간을 차지하고,
        // 필터 바·배지·장소 칩은 Positioned로 위에 올림.
        // Expanded inside scroll view를 쓰지 않아 NestedScrollView에서도 안전.
        final totalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height - 160;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // ── 지도 (전체 공간) ──────────────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 11.5),
                  onMapCreated: (ctrl) {
                    _controller.complete(ctrl);
                    if (filtered.isNotEmpty) _fitBounds();
                  },
                  style: widget.mapStyle,
                  markers: _buildMarkers(filtered),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              // ── 카테고리 필터 칩 (상단 고정) ────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: filterBarHeight,
                child: Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        final count = cat == '전체'
                            ? widget.pins.length
                            : widget.pins.where((p) => p.category == cat).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _onCategorySelected(cat),
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
                                widget.pins.isEmpty ? cat : '$cat  $count',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── 핀 없을 때 안내 오버레이 ─────────────────────────────
              if (widget.pins.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: filterBarHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_location_alt_outlined, size: 36, color: AppTheme.primary),
                        SizedBox(height: 8),
                        Text('핀을 등록하면 지도에 표시돼요',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),

              // ── 우상단 배지 ───────────────────────────────────────────
              Positioned(
                top: filterBarHeight + 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
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
                          Text(
                            _selectedCategory == '전체'
                                ? '내 핀 ${widget.pins.length}개'
                                : '$_selectedCategory ${filtered.length}개',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (filtered.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _fitBounds,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fit_screen_outlined, size: 14, color: AppTheme.textSecondary),
                              SizedBox(width: 4),
                              Text('전체보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── 하단 장소 칩 (핀 있을 때만) ──────────────────────────
              if (filtered.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: placeChipsHeight,
                  child: Container(
                    color: AppTheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text(
                            _selectedCategory == '전체' ? '방문한 장소' : '$_selectedCategory 장소',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) => _PlaceChip(pin: filtered[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceChip extends StatelessWidget {
  final PinModel pin;
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
            pin.title,
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
  final List<PinModel> pins;
  const _SavedTab({required this.pins});

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return const Center(
        child: Text('저장된 핀이 없어요',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            pin.photoPath != null && !kIsWeb
                ? Image.file(File(pin.photoPath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))
                : Container(color: Colors.grey[200]),
            const Center(child: Icon(Icons.bookmark, size: 28, color: AppTheme.primary)),
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
                  pin.category,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
