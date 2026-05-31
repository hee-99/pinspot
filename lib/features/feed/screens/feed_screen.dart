import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/landmark_info_model.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/landmark_info_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/widgets/translatable_text.dart';

// ─── 더미 데이터 ────────────────────────────────────────────────────────────────

class _FeedPost {
  final String pinplerName;
  final String handle;
  final Color avatarColor;
  final bool isFollowing;
  final String location;
  final String district;
  final String category;
  final Color categoryColor;
  final String timeAgo;
  final int likes;
  final int saves;
  final double pinDx;
  final double pinDy;
  final double lat;
  final double lng;

  const _FeedPost({
    required this.pinplerName,
    required this.handle,
    required this.avatarColor,
    required this.isFollowing,
    required this.location,
    required this.district,
    required this.category,
    required this.categoryColor,
    required this.timeAgo,
    required this.likes,
    required this.saves,
    required this.pinDx,
    required this.pinDy,
    required this.lat,
    required this.lng,
  });
}

const _allPosts = [
  _FeedPost(
    pinplerName: '산악대장', handle: '@mountainking',
    avatarColor: Color(0xFF4CAF50), isFollowing: true,
    location: '북한산 백운대 정상', district: '서울 강북구',
    category: '등산/명산', categoryColor: Color(0xFF4CAF50),
    timeAgo: '23분 전', likes: 312, saves: 87,
    pinDx: 0.35, pinDy: 0.40, lat: 37.6558, lng: 126.9780,
  ),
  _FeedPost(
    pinplerName: '렌즈탐험가', handle: '@lensexplorer',
    avatarColor: Color(0xFFFF9800), isFollowing: false,
    location: '을지로 골목 벽화', district: '서울 중구',
    category: '사진 명소', categoryColor: Color(0xFFFF9800),
    timeAgo: '1시간 전', likes: 541, saves: 203,
    pinDx: 0.55, pinDy: 0.30, lat: 37.5663, lng: 126.9906,
  ),
  _FeedPost(
    pinplerName: '산악대장', handle: '@mountainking',
    avatarColor: Color(0xFF4CAF50), isFollowing: true,
    location: '도봉산 오봉 전망대', district: '서울 도봉구',
    category: '등산/명산', categoryColor: Color(0xFF4CAF50),
    timeAgo: '3시간 전', likes: 228, saves: 64,
    pinDx: 0.60, pinDy: 0.25, lat: 37.6997, lng: 127.0273,
  ),
  _FeedPost(
    pinplerName: '트레일러버', handle: '@traillover',
    avatarColor: Color(0xFF2196F3), isFollowing: true,
    location: '수락산 철모바위', district: '서울 노원구',
    category: '등산/명산', categoryColor: Color(0xFF4CAF50),
    timeAgo: '5시간 전', likes: 189, saves: 55,
    pinDx: 0.28, pinDy: 0.55, lat: 37.6813, lng: 127.0681,
  ),
  _FeedPost(
    pinplerName: '도시폐허러', handle: '@urbanruin',
    avatarColor: Color(0xFF795548), isFollowing: false,
    location: '성수동 폐공장 B동', district: '서울 성동구',
    category: '폐허/어반', categoryColor: Color(0xFF795548),
    timeAgo: '8시간 전', likes: 763, saves: 341,
    pinDx: 0.70, pinDy: 0.60, lat: 37.5443, lng: 127.0557,
  ),
  _FeedPost(
    pinplerName: '새벽산행러', handle: '@dawnhiker',
    avatarColor: Color(0xFF9C27B0), isFollowing: true,
    location: '관악산 일출 포인트', district: '서울 관악구',
    category: '등산/명산', categoryColor: Color(0xFF4CAF50),
    timeAgo: '어제', likes: 445, saves: 132,
    pinDx: 0.42, pinDy: 0.68, lat: 37.4413, lng: 126.9633,
  ),
];

// ─── 피드 화면 ─────────────────────────────────────────────────────────────────

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<int, bool> _liked = {};
  final Map<int, bool> _saved = {};
  List<PinModel> _savedPins = [];
  List<({PinModel pin, CommunityModel community})> _communityPins = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    PinRefreshNotifier.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    PinRefreshNotifier.instance.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final pins = await PinService.getPins();
    final communityPins = await CommunityService.getJoinedCommunityPins();
    if (mounted) setState(() { _savedPins = pins; _communityPins = communityPins; });
  }

  void _toggleLike(int index) => setState(() => _liked[index] = !(_liked[index] ?? false));
  void _toggleSave(int index) => setState(() => _saved[index] = !(_saved[index] ?? false));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'PINSPOT',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: AppLocalizations.of(context).feedTabAll),
            Tab(text: AppLocalizations.of(context).feedTabFollowing),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedList(
            posts: _allPosts,
            savedPins: _savedPins,
            communityPins: _communityPins,
            liked: _liked,
            saved: _saved,
            onLike: _toggleLike,
            onSave: _toggleSave,
          ),
          _FeedList(
            posts: _allPosts.where((p) => p.isFollowing).toList(),
            savedPins: _savedPins,
            communityPins: _communityPins,
            liked: _liked,
            saved: _saved,
            onLike: (i) {
              final realIndex = _allPosts.indexOf(_allPosts.where((p) => p.isFollowing).toList()[i]);
              _toggleLike(realIndex);
            },
            onSave: (i) {
              final realIndex = _allPosts.indexOf(_allPosts.where((p) => p.isFollowing).toList()[i]);
              _toggleSave(realIndex);
            },
            emptyMessage: AppLocalizations.of(context).noFollowing,
          ),
        ],
      ),
    );
  }
}

// ─── 피드 리스트 ──────────────────────────────────────────────────────────────

class _FeedList extends StatelessWidget {
  final List<_FeedPost> posts;
  final List<PinModel> savedPins;
  final List<({PinModel pin, CommunityModel community})> communityPins;
  final Map<int, bool> liked;
  final Map<int, bool> saved;
  final ValueChanged<int> onLike;
  final ValueChanged<int> onSave;
  final String? emptyMessage;

  const _FeedList({
    required this.posts,
    this.savedPins = const [],
    this.communityPins = const [],
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavedPins = savedPins.isNotEmpty;
    final hasCommunityPins = communityPins.isNotEmpty;
    if (posts.isEmpty && !hasSavedPins && !hasCommunityPins) {
      return Center(
        child: Text(
          emptyMessage ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.neutral500, fontSize: 14, height: 1.6),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        if (hasSavedPins) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(text: AppLocalizations.of(context).myPins, count: savedPins.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.only(bottom: i < savedPins.length - 1 ? 12 : 0),
                child: _MyPinCard(pin: savedPins[i]),
              ),
              childCount: savedPins.length,
            ),
          ),
        ],
        if (hasCommunityPins) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(text: AppLocalizations.of(context).communityFeed, count: communityPins.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = communityPins[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i < communityPins.length - 1 ? 12 : 0),
                  child: _CommunityPinCard(pin: item.pin, community: item.community),
                );
              },
              childCount: communityPins.length,
            ),
          ),
        ],
        if (posts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(text: hasCommunityPins || hasSavedPins ? AppLocalizations.of(context).pinplerFeed : null),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < posts.length - 1 ? 12 : 0),
                  child: _FeedCard(
                    post: post,
                    isLiked: liked[index] ?? false,
                    isSaved: saved[index] ?? false,
                    onLike: () => onLike(index),
                    onSave: () => onSave(index),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(top: 12, bottom: 12)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String? text;
  final int? count;
  const _SectionLabel({this.text, this.count});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(
            text!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neutral500),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 내 핀 카드 ───────────────────────────────────────────────────────────────

class _MyPinCard extends StatelessWidget {
  final PinModel pin;
  const _MyPinCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    final isDanger = pin.category.contains('위험');
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 풀블리드 사진 + 오버레이 ────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  SizedBox(height: 220, width: double.infinity, child: _buildPhoto()),
                  // 카테고리/위험 배지
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDanger ? const Color(0xFFDC2626) : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isDanger) ...[
                          const Text('⚠️', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                        ],
                        Text(pin.category,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  // 바텀 그라디언트 오버레이
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 105,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xD9000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // 제목 (사진 위)
                  Positioned(
                    bottom: 12, left: 14, right: 14,
                    child: Row(children: [
                      Icon(
                        isDanger ? Icons.warning_amber_rounded : Icons.location_on,
                        size: 14,
                        color: isDanger ? const Color(0xFFFFB300) : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TranslatableText(
                          pin.title,
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.4,
                            shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            // ── 하단 바 ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 13, color: AppColors.neutral400),
                  const SizedBox(width: 4),
                  Text(_timeAgo(pin.createdAt, context),
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: TranslatableText(pin.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://maps.google.com/?daddr=${pin.lat},${pin.lng}&directionsmode=driving',
                      );
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.navigation, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).directions,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (pin.photoPath != null && !kIsWeb) {
      return Image.file(File(pin.photoPath!),
          width: double.infinity, height: 220, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder());
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5EE), Color(0xFFD4EDDC)],
        ),
      ),
      child: Center(
        child: Icon(Icons.location_on_outlined, size: 52,
            color: AppColors.primary.withValues(alpha: 0.25)),
      ),
    );
  }
}

// ─── 커뮤니티 핀 카드 ─────────────────────────────────────────────────────────

class _CommunityPinCard extends StatelessWidget {
  final PinModel pin;
  final CommunityModel community;
  const _CommunityPinCard({required this.pin, required this.community});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _buildPhoto(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: community.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 12))),
                      ),
                      const SizedBox(width: 6),
                      Text(community.name,
                          style: TextStyle(fontSize: 12, color: community.color, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(_timeAgo(pin.createdAt, context),
                          style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: TranslatableText(pin.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TranslatableText(pin.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(pin.category,
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (pin.photoPath != null && !kIsWeb) {
      return Image.file(File(pin.photoPath!), width: double.infinity, height: 160, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: double.infinity, height: 90,
    decoration: BoxDecoration(gradient: LinearGradient(
      colors: [community.color.withValues(alpha: 0.12), community.color.withValues(alpha: 0.06)],
    )),
    child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 36))),
  );
}

// ─── 저장 핀 상세 화면 ─────────────────────────────────────────────────────────

class _SavedPinDetailScreen extends StatefulWidget {
  final PinModel pin;
  const _SavedPinDetailScreen({required this.pin});

  @override
  State<_SavedPinDetailScreen> createState() => _SavedPinDetailScreenState();
}

class _SavedPinDetailScreenState extends State<_SavedPinDetailScreen> {
  final _mapCtrl = Completer<GoogleMapController>();
  LandmarkInfo? _landmarkInfo;
  bool _isLoadingInfo = true;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadLandmarkInfo();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  Future<void> _loadLandmarkInfo() async {
    final info = await LandmarkInfoService.fetchInfo(
      placeName: widget.pin.title,
      lat: widget.pin.lat,
      lng: widget.pin.lng,
    );
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://maps.google.com/?daddr=${widget.pin.lat},${widget.pin.lng}&directionsmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mapAppError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _share() {
    final pin = widget.pin;
    Share.share(
      '📍 ${pin.title} (${pin.category})\n'
      'https://maps.google.com/?q=${pin.lat},${pin.lng}',
      subject: pin.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.neutral900,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(pin.lat, pin.lng),
                  zoom: 15,
                ),
                onMapCreated: _mapCtrl.complete,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                style: _mapStyle,
                markers: {
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(pin.lat, pin.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).myPinLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(pin.createdAt, context),
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TranslatableText(
                    pin.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pin.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TranslatableText(
                      pin.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral500,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (pin.photoPath != null && !kIsWeb) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(pin.photoPath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ],
                  // AI 장소 정보 카드
                  const SizedBox(height: 20),
                  _LandmarkInfoWidget(
                    isLoading: _isLoadingInfo,
                    info: _landmarkInfo,
                    onRefresh: _loadLandmarkInfo,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                          label: Text(
                            AppLocalizations.of(context).directions,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: IconButton(
                          onPressed: _share,
                          icon: const Icon(
                            Icons.ios_share_outlined,
                            color: AppColors.neutral900,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 피드 카드 ────────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  final _FeedPost post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;

  const _FeedCard({
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PinDetailScreen(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDanger = post.category.contains('위험');
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 풀블리드 지도 + 오버레이 ─────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  SizedBox(height: 230, width: double.infinity,
                      child: _MapThumbnail(post: post)),
                  // 카테고리/위험 배지
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDanger ? const Color(0xFFDC2626) : post.categoryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isDanger) ...[
                          const Text('⚠️', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                        ],
                        Text(post.category,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  // 바텀 그라디언트 오버레이
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 115,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xD9000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // 위치 텍스트 (그라디언트 위)
                  Positioned(
                    bottom: 12, left: 14, right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            isDanger ? Icons.warning_amber_rounded : Icons.location_on,
                            size: 13,
                            color: isDanger ? const Color(0xFFFFB300) : Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(post.location,
                              style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.4,
                                shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(post.district,
                          style: TextStyle(fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.78),
                              shadows: const [Shadow(color: Color(0x44000000), blurRadius: 4)]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── 유저 정보 + 액션 바 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: post.avatarColor,
                    child: Text(post.pinplerName[0],
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(post.pinplerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context).pinpler,
                              style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                        Text(post.timeAgo,
                            style: const TextStyle(fontSize: 10, color: AppColors.neutral400)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _ActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_outline,
                        label: _fmt(post.likes + (isLiked ? 1 : 0)),
                        color: isLiked ? Colors.redAccent : AppColors.neutral400,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 14),
                      _ActionButton(
                        icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        label: _fmt(post.saves + (isSaved ? 1 : 0)),
                        color: isSaved ? AppColors.primary : AppColors.neutral400,
                        onTap: onSave,
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => Share.share(
                          '📍 ${post.location} (${post.category})\n${post.district}\n핀스팟에서 발견한 숨겨진 장소!',
                          subject: post.location,
                        ),
                        child: const Icon(Icons.ios_share_outlined, size: 18, color: AppColors.neutral400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ─── 핀 상세 화면 (핀플 피드) ──────────────────────────────────────────────────

class _PinDetailScreen extends StatefulWidget {
  final _FeedPost post;
  const _PinDetailScreen({required this.post});

  @override
  State<_PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<_PinDetailScreen> {
  final _mapCtrl = Completer<GoogleMapController>();
  LandmarkInfo? _landmarkInfo;
  bool _isLoadingInfo = true;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadLandmarkInfo();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    if (mounted) setState(() => _mapStyle = style);
  }

  Future<void> _loadLandmarkInfo() async {
    final info = await LandmarkInfoService.fetchInfo(
      placeName: widget.post.location,
      lat: widget.post.lat,
      lng: widget.post.lng,
    );
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://maps.google.com/?daddr=${widget.post.lat},${widget.post.lng}&directionsmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mapAppError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _share() {
    Share.share(
      '📍 ${widget.post.location} (${widget.post.category})\n'
      '${widget.post.district}\n'
      'https://maps.google.com/?q=${widget.post.lat},${widget.post.lng}',
      subject: widget.post.location,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.neutral900,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(post.lat, post.lng),
                  zoom: 15,
                ),
                onMapCreated: _mapCtrl.complete,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                style: _mapStyle,
                markers: {
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(post.lat, post.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: post.avatarColor,
                        child: Text(
                          post.pinplerName[0],
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.pinplerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(post.handle, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                        ],
                      ),
                      const Spacer(),
                      Text(post.timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    post.location,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(post.district, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: post.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.category,
                          style: TextStyle(fontSize: 11, color: post.categoryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${post.lat.toStringAsFixed(4)}, ${post.lng.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                  // AI 장소 정보 카드
                  const SizedBox(height: 16),
                  _LandmarkInfoWidget(
                    isLoading: _isLoadingInfo,
                    info: _landmarkInfo,
                    onRefresh: _loadLandmarkInfo,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                          label: Text(
                            AppLocalizations.of(context).directions,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: IconButton(
                          onPressed: _share,
                          icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── 지도 썸네일 ──────────────────────────────────────────────────────────────

class _MapThumbnail extends StatelessWidget {
  final _FeedPost post;

  const _MapThumbnail({required this.post});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 다크 나이트맵 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1F12), Color(0xFF1A3A20)],
              ),
            ),
          ),
          CustomPaint(painter: _NightMapPainter()),
          // 핀 마커
          Align(
            alignment: Alignment(
              (post.pinDx * 2 - 1).clamp(-0.75, 0.75),
              (post.pinDy * 2 - 1).clamp(-0.75, 0.75),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 글로우 링
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: post.avatarColor.withValues(alpha: 0.2),
                    border: Border.all(color: post.avatarColor.withValues(alpha: 0.5), width: 1),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: post.avatarColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: post.avatarColor.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: Text(
                          post.pinplerName[0],
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        post.location.length > 9 ? '${post.location.substring(0, 9)}…' : post.location,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.location_on, color: post.avatarColor, size: 26),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: post.categoryColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.category,
                    style: TextStyle(fontSize: 10, color: post.categoryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI 장소 정보 위젯 ─────────────────────────────────────────────────────────

class _LandmarkInfoWidget extends StatelessWidget {
  final bool isLoading;
  final LandmarkInfo? info;
  final VoidCallback onRefresh;

  const _LandmarkInfoWidget({
    required this.isLoading,
    required this.info,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).aiLoading,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
            ),
          ],
        ),
      );
    }

    if (info == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).aiInfo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    info!.sourceLabel,
                    style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LandmarkRow(
                  icon: Icons.history_edu_outlined,
                  label: AppLocalizations.of(context).originHistory,
                  text: info!.origin,
                ),
                const SizedBox(height: 10),
                _LandmarkRow(
                  icon: Icons.place_outlined,
                  label: AppLocalizations.of(context).highlights,
                  text: info!.highlights,
                ),
                if (info!.bestTime != null && info!.bestTime!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _LandmarkRow(
                    icon: Icons.calendar_today_outlined,
                    label: AppLocalizations.of(context).bestTime,
                    text: info!.bestTime!,
                  ),
                ],
                if (info!.tip != null && info!.tip!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _LandmarkRow(
                    icon: Icons.tips_and_updates_outlined,
                    label: AppLocalizations.of(context).visitTip,
                    text: info!.tip!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _LandmarkRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              TranslatableText(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NightMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 다크 블록 (건물 구역)
    final blockPaint = Paint()..color = const Color(0xFF1E3A24)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width * 0.28, size.height * 0.45), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, 0, size.width * 0.32, size.height * 0.38), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.08, size.width * 0.22, size.height * 0.3), blockPaint);

    // 강 (반투명 파랑)
    final waterPaint = Paint()..color = const Color(0x442979B3)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.45, size.height * 0.6, size.width * 0.2, size.height * 0.4), waterPaint);

    // 주요 도로 (빛나는 선)
    final highway = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.35)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.40), Offset(size.width, size.height * 0.44), highway);

    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.40, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.70), Offset(size.width * 0.55, size.height * 0.62), road);
    canvas.drawLine(Offset(size.width * 0.60, size.height), Offset(size.width, size.height * 0.48), road);

    // 가는 도로
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.20), Offset(size.width * 0.42, size.height * 0.22), thin);
    canvas.drawLine(Offset(size.width * 0.58, 0), Offset(size.width * 0.62, size.height * 0.38), thin);

    // 빛 산란 (중앙 글로우)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x2216A34A), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.width * 0.45,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_NightMapPainter old) => false;
}

// ─── 유틸 ──────────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt, BuildContext context) {
  return AppLocalizations.of(context).timeAgo(dt);
}
