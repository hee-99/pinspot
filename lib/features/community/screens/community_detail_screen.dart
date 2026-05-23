import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/community_model.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/services/community_service.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _isJoined = widget.community.isJoined;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleJoin() async {
    await CommunityService.toggleJoin(widget.community.id);
    setState(() => _isJoined = !_isJoined);
  }

  void _share() {
    Share.share(
      '📍 핀스팟 커뮤니티 — ${widget.community.emoji} ${widget.community.name}\n'
      '${widget.community.description}\n\n'
      '멤버 ${_formatCount(widget.community.memberCount)}명이 함께하고 있어요!',
      subject: widget.community.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.community.color;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
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
              IconButton(
                icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
                onPressed: _share,
              ),
            ],
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
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surface,
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
                  else if (!widget.community.isOwner)
                    GestureDetector(
                      onTap: _toggleJoin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: _isJoined
                              ? AppTheme.background
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
                  Tab(text: '핀 피드'),
                  Tab(text: '지도'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _PinFeedTab(community: widget.community),
            _MapTab(community: widget.community),
          ],
        ),
      ),
    );
  }
}

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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

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

class _PinFeedTab extends StatefulWidget {
  final CommunityModel community;
  const _PinFeedTab({required this.community});

  @override
  State<_PinFeedTab> createState() => _PinFeedTabState();
}

class _PinFeedTabState extends State<_PinFeedTab> {
  List<PinModel> _pins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pins = await CommunityService.getCommunityPins(widget.community.id);
    if (mounted) setState(() { _pins = pins; _loading = false; });
  }

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

class _CommunityDetailPinCard extends StatelessWidget {
  final PinModel pin;
  final Color color;
  const _CommunityDetailPinCard({required this.pin, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
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

  Widget _mapPlaceholder() => Container(
    height: 80,
    decoration: BoxDecoration(gradient: LinearGradient(
      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
    )),
    child: Center(child: Icon(Icons.location_on, color: color.withValues(alpha: 0.5), size: 32)),
  );
}

class _MapTab extends StatefulWidget {
  final CommunityModel community;
  const _MapTab({required this.community});

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final _mapCtrl = Completer<GoogleMapController>();
  List<PinModel> _pins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pins = await CommunityService.getCommunityPins(widget.community.id);
    if (mounted) setState(() { _pins = pins; _loading = false; });
  }

  Set<Marker> get _markers => _pins.map((pin) => Marker(
    markerId: MarkerId(pin.id),
    position: LatLng(pin.lat, pin.lng),
    infoWindow: InfoWindow(title: pin.title, snippet: pin.category),
    icon: BitmapDescriptor.defaultMarkerWithHue(14.0),
  )).toSet();

  LatLng get _center {
    if (_pins.isEmpty) return const LatLng(37.5665, 126.9780);
    return LatLng(
      _pins.map((p) => p.lat).reduce((a, b) => a + b) / _pins.length,
      _pins.map((p) => p.lng).reduce((a, b) => a + b) / _pins.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 60, color: widget.community.color.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('공유된 핀이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('핀을 공유하면 지도에 표시돼요',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 11),
      onMapCreated: _mapCtrl.complete,
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}
