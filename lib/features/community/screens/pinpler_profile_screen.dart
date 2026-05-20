import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'pinpler_ranking_screen.dart';

class PinplerProfileScreen extends StatelessWidget {
  final PinplerData pinpler;
  final String category;
  final Color categoryColor;

  const PinplerProfileScreen({
    super.key,
    required this.pinpler,
    required this.category,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(pinpler: pinpler, categoryColor: categoryColor, category: category),
          SliverToBoxAdapter(child: _StatsRow(pinpler: pinpler)),
          const SliverToBoxAdapter(child: _SectionTitle(title: '나의 핀 지도')),
          SliverToBoxAdapter(child: _PinMap(pinpler: pinpler)),
          const SliverToBoxAdapter(child: _SectionTitle(title: '최근 핀')),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PinListItem(pin: pinpler.pins[index], categoryColor: categoryColor),
              childCount: pinpler.pins.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─── 앱바 ─────────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final PinplerData pinpler;
  final Color categoryColor;
  final String category;

  const _ProfileAppBar({required this.pinpler, required this.categoryColor, required this.category});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.8),
                    categoryColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 33,
                      backgroundColor: pinpler.avatarColor,
                      child: Text(pinpler.name[0], style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(pinpler.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            child: Text('핀플', style: TextStyle(fontSize: 10, color: categoryColor, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(pinpler.handle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                        child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('팔로우', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── 통계 ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final PinplerData pinpler;
  const _StatsRow({required this.pinpler});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(label: '핀', value: '${pinpler.pinCount}', icon: Icons.location_on, color: AppTheme.primary),
          Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
          _StatItem(label: '좋아요', value: _fmt(pinpler.likes), icon: Icons.favorite, color: Colors.redAccent),
          Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
          _StatItem(label: '저장', value: _fmt(pinpler.saves), icon: Icons.bookmark, color: Colors.amber[700]!),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ─── 섹션 타이틀 ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── 핀플 지도 (Google Maps) ──────────────────────────────────────────────────

class _PinMap extends StatefulWidget {
  final PinplerData pinpler;
  const _PinMap({required this.pinpler});

  @override
  State<_PinMap> createState() => _PinMapState();
}

class _PinMapState extends State<_PinMap> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng get _center {
    final pins = widget.pinpler.pins;
    final lat = pins.map((p) => p.lat).reduce((a, b) => a + b) / pins.length;
    final lng = pins.map((p) => p.lng).reduce((a, b) => a + b) / pins.length;
    return LatLng(lat, lng);
  }

  Set<Marker> get _markers => widget.pinpler.pins.map((pin) => Marker(
    markerId: MarkerId(pin.name),
    position: LatLng(pin.lat, pin.lng),
    infoWindow: InfoWindow(title: pin.name, snippet: pin.category),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  )).toSet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 11.5),
          onMapCreated: (c) => _controller.complete(c),
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}

// ─── 핀 목록 아이템 ───────────────────────────────────────────────────────────

class _PinListItem extends StatelessWidget {
  final PinLocation pin;
  final Color categoryColor;

  const _PinListItem({required this.pin, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.location_on, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pin.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(pin.category, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
        ],
      ),
    );
  }
}
