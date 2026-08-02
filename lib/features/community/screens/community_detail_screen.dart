import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pinspot/design/theme/app_theme.dart';
import 'package:pinspot/core/models/community_model.dart';
import 'package:pinspot/core/models/pin_model.dart';
import 'package:pinspot/features/community/services/community_service.dart';
import 'package:pinspot/design/utils/marker_builder.dart';

// 커뮤니티 상세 화면 — 순위/핀 피드/지도 탭으로 구성된 최상위 위젯
class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

// 커뮤니티 상세 화면의 상태 관리 — 탭 컨트롤러와 참여 여부를 보관
class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late bool _isJoined;

  @override
  void initState() {
    // 순위/핀 피드/지도 3개 탭 컨트롤러 초기화 및 현재 참여 상태 로드
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _isJoined = widget.community.isJoined;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // 커뮤니티 참여/탈퇴 상태를 서버(로컬 저장소)에 토글 저장
  Future<void> _toggleJoin() async {
    await CommunityService.toggleJoin(widget.community.id);
    setState(() => _isJoined = !_isJoined);
  }

  // 커뮤니티 정보를 외부 앱으로 공유
  void _share() {
    Share.share(
      '📍 핀스팟 커뮤니티 — ${widget.community.emoji} ${widget.community.name}\n'
      '${widget.community.description}\n\n'
      '멤버 ${_formatCount(widget.community.memberCount)}명이 함께하고 있어요!',
      subject: widget.community.name,
    );
  }

  // 커뮤니티 상세 화면 전체 레이아웃 — 확장형 헤더 + 통계 바 + 고정 탭바 + 탭별 콘텐츠
  @override
  Widget build(BuildContext context) {
    final color = widget.community.color;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: NestedScrollView(
        // 스크롤에 따라 접히는 헤더 영역(커버 이미지/제목) 정의
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // 공유 버튼
              IconButton(
                icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
                onPressed: _share,
              ),
            ],
            // 커뮤니티 색상 기반 그라데이션 배경 + 이모지/이름/설명 표시
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(widget.community.emoji,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(widget.community.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        if (widget.community.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(widget.community.description,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 멤버 수/핀 수 통계 및 초대코드·참여버튼 영역
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _StatChip(
                      icon: Icons.people_outline,
                      label: '${_formatCount(widget.community.memberCount)}명',
                      color: color),
                  const SizedBox(width: 12),
                  _StatChip(
                      icon: Icons.location_on_outlined,
                      label: '핀 ${_formatCount(widget.community.pinCount)}개',
                      color: color),
                  const Spacer(),
                  // 비공개 커뮤니티인 경우 초대 코드를 탭하면 클립보드로 복사
                  if (widget.community.isPrivate && widget.community.joinCode != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.community.joinCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('초대 코드 ${widget.community.joinCode} 복사됐어요'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: color,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 13, color: color),
                            const SizedBox(width: 5),
                            Text(widget.community.joinCode!,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2, color: color)),
                            const SizedBox(width: 6),
                            Icon(Icons.copy_rounded, size: 13, color: color),
                          ],
                        ),
                      ),
                    )
                  // 소유자가 아니면 참여/참여중 토글 버튼 표시
                  else if (!widget.community.isOwner)
                    GestureDetector(
                      onTap: _toggleJoin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: _isJoined
                              ? const Color(0xFFF5F3EE)
                              : color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _isJoined
                                  ? const Color(0xFFDDDDDD)
                                  : color),
                        ),
                        child: Text(
                          _isJoined ? '참여 중' : '참여하기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isJoined
                                ? AppTheme.textSecondary
                                : Colors.white,
                          ),
                        ),
                      ),
                    )
                  // 소유자인 경우 "내가 만든 커뮤니티" 배지 표시
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 13, color: color),
                          const SizedBox(width: 4),
                          Text('내가 만든 커뮤니티',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 스크롤 시 상단에 고정되는 탭바(순위/핀 피드/지도)
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                indicatorColor: color,
                labelColor: color,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: '순위'),
                  Tab(text: '핀 피드'),
                  Tab(text: '지도'),
                ],
              ),
            ),
          ),
        ],
        // 탭 순서: 순위(리더보드) → 핀 피드 → 지도
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _LeaderboardTab(community: widget.community),
            _PinFeedTab(community: widget.community),
            _MapTab(community: widget.community),
          ],
        ),
      ),
    );
  }
}

// 아이콘 + 라벨 형태의 작은 통계 칩(멤버 수, 핀 수 등)
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ],
    );
  }
}

// NestedScrollView에서 탭바를 상단에 고정시키기 위한 delegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  // 고정 높이 컨테이너에 탭바를 감싸 반환
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// 핀 피드 탭 — 커뮤니티에 공유된 핀 목록을 카드 리스트로 표시
class _PinFeedTab extends StatefulWidget {
  final CommunityModel community;
  const _PinFeedTab({required this.community});

  @override
  State<_PinFeedTab> createState() => _PinFeedTabState();
}

// 핀 피드 탭의 상태 관리 — 핀 목록 로딩 상태 보관
class _PinFeedTabState extends State<_PinFeedTab> {
  List<PinModel> _pins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // 커뮤니티에 공유된 핀 목록을 불러옴
  Future<void> _load() async {
    final pins = await CommunityService.getCommunityPins(widget.community.id);
    if (mounted) setState(() { _pins = pins; _loading = false; });
  }

  // 로딩 중/빈 상태/핀 목록 순으로 화면 구성
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_pins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: widget.community.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Text(widget.community.emoji, style: const TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 20),
              const Text('아직 핀이 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('핀 등록 후 이 커뮤니티에 공유하면\n여기서 모아볼 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _pins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CommunityDetailPinCard(pin: _pins[i], color: widget.community.color),
    );
  }
}

// 핀 피드 리스트에 표시되는 개별 핀 카드
class _CommunityDetailPinCard extends StatelessWidget {
  final PinModel pin;
  final Color color;
  const _CommunityDetailPinCard({required this.pin, required this.color});

  // 사진 썸네일 + 제목/카테고리/설명/좌표로 구성된 카드 UI
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pin.photoPath != null && !kIsWeb)
            Image.file(File(pin.photoPath!), width: double.infinity, height: 160, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _mapPlaceholder())
          else
            _mapPlaceholder(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(pin.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(pin.category,
                          style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                if (pin.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(pin.description,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Text(
                  '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 사진이 없는 핀을 위한 대체 배경(위치 아이콘)
  Widget _mapPlaceholder() => Container(
    height: 80,
    decoration: BoxDecoration(gradient: LinearGradient(
      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
    )),
    child: Center(child: Icon(Icons.location_on, color: color.withValues(alpha: 0.5), size: 32)),
  );
}

// 지도 탭 — 커뮤니티에 공유된 핀을 지도 위 클러스터 마커로 표시
class _MapTab extends StatefulWidget {
  final CommunityModel community;
  const _MapTab({required this.community});

  @override
  State<_MapTab> createState() => _MapTabState();
}

// 지도 탭의 상태 관리 — 핀/마커/지도 스타일 로딩 상태 보관
class _MapTabState extends State<_MapTab> {
  final _mapCtrl = Completer<GoogleMapController>();
  List<PinModel> _pins = [];
  bool _loading = true;
  String? _mapStyle;
  Set<Marker> _markers = {};

  @override
  void initState() {
    // 지도 스타일과 핀 데이터를 병행 로드
    super.initState();
    _loadMapStyle();
    _load();
  }

  // 지도 커스텀 스타일 JSON 에셋 로드
  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  // 커뮤니티 핀 목록을 불러온 뒤 지도 마커를 생성
  Future<void> _load() async {
    final pins = await CommunityService.getCommunityPins(widget.community.id);
    if (!mounted) return;
    setState(() { _pins = pins; _loading = false; });
    await _buildMarkers(pins);
  }

  // 가까운 위치의 핀들을 클러스터로 묶어 지도 마커 아이콘 생성
  Future<void> _buildMarkers(List<PinModel> pins) async {
    final clusters = MarkerBuilder.clusterByLocation<PinModel>(
      items: pins,
      getLat: (p) => p.lat,
      getLng: (p) => p.lng,
      radiusMeters: 80,
    );

    final accent = widget.community.color;
    final Set<Marker> built = {};

    for (final cluster in clusters) {
      final rep = cluster.firstWhere(
        (p) => p.photoPath != null,
        orElse: () => cluster.first,
      );
      final icon = await MarkerBuilder.buildClusterMarker(
        rep.photoPath,
        cluster.length,
        accent: accent,
      );
      built.add(Marker(
        markerId: MarkerId('cluster_${rep.id}'),
        position: LatLng(rep.lat, rep.lng),
        icon: icon,
        onTap: () => _showPinSheet(rep, cluster.length),
      ));
    }

    if (mounted) setState(() => _markers = built);
  }

  // 마커 탭 시 핀(또는 클러스터) 정보를 바텀시트로 표시
  void _showPinSheet(PinModel pin, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CommunityPinSheet(
        pin: pin,
        count: count,
        color: widget.community.color,
      ),
    );
  }

  // 모든 핀 좌표의 평균값으로 지도 초기 중심점 계산
  LatLng get _center {
    if (_pins.isEmpty) return const LatLng(37.5665, 126.9780);
    return LatLng(
      _pins.map((p) => p.lat).reduce((a, b) => a + b) / _pins.length,
      _pins.map((p) => p.lng).reduce((a, b) => a + b) / _pins.length,
    );
  }

  // 로딩/빈 상태/지도(마커+배지+중심이동버튼) 순으로 화면 구성
  @override
  Widget build(BuildContext context) {
    final color = widget.community.color;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 60, color: color.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('공유된 핀이 없어요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('핀을 공유하면 지도에 표시돼요',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 12),
          onMapCreated: _mapCtrl.complete,
          style: _mapStyle,
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        // 핀 수 요약 배지
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: color),
                  const SizedBox(width: 5),
                  Text(
                    '핀 ${_pins.length}개',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 중심으로 이동 버튼
        Positioned(
          bottom: 20,
          right: 16,
          child: GestureDetector(
            onTap: () async {
              final ctrl = await _mapCtrl.future;
              ctrl.animateCamera(CameraUpdate.newLatLngZoom(_center, 12));
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.center_focus_strong_rounded, color: color, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// 지도에서 마커를 탭했을 때 뜨는 핀 상세 정보 바텀시트
class _CommunityPinSheet extends StatelessWidget {
  final PinModel pin;
  final int count;
  final Color color;

  const _CommunityPinSheet({
    required this.pin,
    required this.count,
    required this.color,
  });

  // 사진, 핀 제목/카테고리, 클러스터 인원 수, 설명을 담은 바텀시트 UI
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pin.photoPath != null && !kIsWeb)
              Image.file(
                File(pin.photoPath!),
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              alignment: Alignment.center,
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pin.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (count > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 13, color: color),
                              const SizedBox(width: 4),
                              Text(
                                '$count명',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pin.category,
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (count > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '이 장소를 $count명이 핀했어요',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      pin.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 큰 숫자를 "1.2k" 형태로 축약 표시
String _formatCount(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}

// ─── Leaderboard ─────────────────────────────────────────────────────────────

// 순위 탭에 표시되는 멤버 데이터 모델
class _Member {
  final String name;
  final Color avatarColor;
  final String emoji;
  final int pins;
  final int likes;
  final int saves;

  const _Member({
    required this.name,
    required this.avatarColor,
    required this.emoji,
    required this.pins,
    required this.likes,
    required this.saves,
  });

  // 핀 5점, 좋아요 2점, 저장 3점 가중치로 순위 점수 계산
  int get score => pins * 5 + likes * 2 + saves * 3;
}

// 순위 탭 — 멤버 순위 포디움과 정렬 가능한 순위 리스트
class _LeaderboardTab extends StatefulWidget {
  final CommunityModel community;
  const _LeaderboardTab({required this.community});

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

// 순위 탭의 상태 관리 — 정렬 기준과 목업 멤버 목록 보관
class _LeaderboardTabState extends State<_LeaderboardTab> {
  static const _sortLabels = ['순위순', '인기순', '추천순'];
  int _sortIdx = 0;
  late List<_Member> _members;

  // 실제 서버 연동 전까지 사용하는 목업 멤버 이름/이모지/색상 데이터
  static const _names = [
    '산악대장', '도시탐험가', '새벽하이커', '사진작가', '핀스팟러',
    '여행고수', '골목탐방', '뷰맛집러', '감성여행자', '핀헌터',
    '로컬가이드', '장소덕후', '지도러버', '핫플마스터', '숨은명소',
    '길찾기왕', '포토스팟킹', '탐험대장', '핀적립왕', '장소수집가',
  ];
  static const _emojis = ['🧗', '🏙️', '🌅', '📸', '📍', '✈️', '🗺️', '🌄', '🎒', '🔍'];
  static const _colors = [
    Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF9C27B0),
    Color(0xFFE91E63), Color(0xFF00BCD4), Color(0xFF795548), Color(0xFF607D8B),
    Color(0xFFFF5722), Color(0xFF3F51B5),
  ];

  @override
  void initState() {
    super.initState();
    _members = _generateMembers();
  }

  // 커뮤니티 ID를 시드로 사용해 항상 동일한 결과를 내는 가짜 멤버 목록 생성(실서버 데이터 아님)
  List<_Member> _generateMembers() {
    final count = max(5, min(widget.community.memberCount, 20));
    return List.generate(count, (i) {
      final r = Random((widget.community.id.hashCode + i * 31).abs());
      return _Member(
        name: _names[i % _names.length],
        avatarColor: _colors[i % _colors.length],
        emoji: _emojis[i % _emojis.length],
        pins: r.nextInt(48) + 2,
        likes: r.nextInt(490) + 10,
        saves: r.nextInt(190) + 5,
      );
    });
  }

  // 선택된 정렬 기준(순위/인기/추천)에 따라 멤버 목록 정렬
  List<_Member> get _sorted {
    final list = [..._members];
    switch (_sortIdx) {
      case 0: list.sort((a, b) => b.score.compareTo(a.score));
      case 1: list.sort((a, b) => (b.likes + b.saves).compareTo(a.likes + a.saves));
      case 2: list.sort((a, b) => b.pins.compareTo(a.pins));
    }
    return list;
  }

  // 포디움(상위 3명) + 정렬 바 + 전체 순위 리스트 구성
  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final color = widget.community.color;
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _Podium(top3: sorted.take(3).toList(), color: color),
        _SortBar(
          labels: _sortLabels,
          selected: _sortIdx,
          color: color,
          onSelect: (i) => setState(() => _sortIdx = i),
        ),
        const SizedBox(height: 4),
        ...sorted.asMap().entries.map((e) => _MemberRow(
          rank: e.key + 1,
          member: e.value,
          color: color,
          sortIdx: _sortIdx,
        )),
      ],
    );
  }
}

// 상위 3명을 시상대 형태로 보여주는 위젯
class _Podium extends StatelessWidget {
  final List<_Member> top3;
  final Color color;
  const _Podium({required this.top3, required this.color});

  // 2등-1등-3등 순서로 배치하여 가운데가 가장 높은 시상대 레이아웃 구성
  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd place
              if (second != null)
                _PodiumSlot(member: second, rank: 2, color: color, heightFactor: 0.78)
              else
                const SizedBox(width: 90),
              const SizedBox(width: 12),
              // 1st place
              _PodiumSlot(member: first, rank: 1, color: color, heightFactor: 1.0),
              const SizedBox(width: 12),
              // 3rd place
              if (third != null)
                _PodiumSlot(member: third, rank: 3, color: color, heightFactor: 0.62)
              else
                const SizedBox(width: 90),
            ],
          ),
        ],
      ),
    );
  }
}

// 시상대의 개별 순위(1/2/3등) 슬롯 — 아바타, 메달, 점수, 단상 블록으로 구성
class _PodiumSlot extends StatelessWidget {
  final _Member member;
  final int rank;
  final Color color;
  final double heightFactor;

  const _PodiumSlot({
    required this.member, required this.rank,
    required this.color, required this.heightFactor,
  });

  // 순위별 메달 이모지, 단상 색상(금/은/동), 단상 높이 매핑
  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _podiumColors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };
  static const _podiumHeights = {1: 80.0, 2: 60.0, 3: 48.0};

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 62.0 : 50.0;
    final podiumColor = _podiumColors[rank]!;

    return SizedBox(
      width: isFirst ? 110 : 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for 1st
          if (isFirst)
            Text('👑', style: TextStyle(fontSize: 20))
          else
            const SizedBox(height: 4),
          const SizedBox(height: 4),
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: member.avatarColor,
                child: Text(
                  member.emoji,
                  style: TextStyle(fontSize: isFirst ? 28 : 22),
                ),
              ),
              Positioned(
                bottom: -4, right: -4,
                child: Container(
                  width: isFirst ? 24 : 20,
                  height: isFirst ? 24 : 20,
                  decoration: BoxDecoration(
                    color: podiumColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: isFirst ? 11 : 9,
                        fontWeight: FontWeight.w900,
                        color: rank == 1 ? Colors.brown.shade800 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            style: TextStyle(
              fontSize: isFirst ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatCount(member.score)}점',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: podiumColor.darken(),
            ),
          ),
          const SizedBox(height: 10),
          // Podium block
          Container(
            width: double.infinity,
            height: _podiumHeights[rank],
            decoration: BoxDecoration(
              color: podiumColor.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_medals[rank]!, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 10, color: Colors.white70),
                    Text(' ${member.pins}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(Icons.favorite, size: 10, color: Colors.white70),
                    Text(' ${_formatCount(member.likes)}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 순위 정렬 기준(순위순/인기순/추천순)을 선택하는 칩 바
class _SortBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final Color color;
  final ValueChanged<int> onSelect;

  const _SortBar({
    required this.labels, required this.selected,
    required this.color, required this.onSelect,
  });

  // 선택된 정렬 라벨을 강조 색상으로 표시하는 칩 목록 렌더링
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final i = e.key;
          final active = i == selected;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? color : const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? color : const Color(0xFFC9C5BE),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 순위 리스트의 개별 멤버 행 — 순위, 아바타, 이름, 통계, 점수 표시
class _MemberRow extends StatelessWidget {
  final int rank;
  final _Member member;
  final Color color;
  final int sortIdx;

  const _MemberRow({
    required this.rank, required this.member,
    required this.color, required this.sortIdx,
  });

  // 1등 강조 스타일 + 순위/아바타/이름/통계/점수를 한 행에 표시
  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final highlight = rank == 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: color.withValues(alpha: 0.25))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: rank <= 3
                ? Text(
                    ['🥇', '🥈', '🥉'][rank - 1],
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: member.avatarColor,
            child: Text(member.emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          // Name + highlighted stat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                _StatRow(member: member, highlightIdx: sortIdx, color: color),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatCount(member.score)}점',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isTop3 ? color : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 멤버 행 하단의 핀/좋아요/저장 통계 아이콘 줄 — 현재 정렬 기준에 해당하는 값 강조
class _StatRow extends StatelessWidget {
  final _Member member;
  final int highlightIdx;
  final Color color;

  const _StatRow({required this.member, required this.highlightIdx, required this.color});

  @override
  Widget build(BuildContext context) {
    // 정렬 기준(순위순=전체, 인기순=좋아요/저장, 추천순=핀)에 맞는 항목만 강조 색상 적용
    final stats = [
      (Icons.location_on_outlined, '${member.pins} 핀'),
      (Icons.favorite_outline, _formatCount(member.likes)),
      (Icons.bookmark_outline, _formatCount(member.saves)),
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final active = (highlightIdx == 0) || (highlightIdx == 1 && e.key >= 1) || (highlightIdx == 2 && e.key == 0);
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              Icon(e.value.$1, size: 12,
                  color: active ? color : AppTheme.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(width: 2),
              Text(e.value.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? color : AppTheme.textSecondary.withValues(alpha: 0.5),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// 포디움 점수 텍스트 등에 쓰이는 색상을 어둡게 만드는 헬퍼
extension _ColorX on Color {
  Color darken([double amount = 0.2]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
