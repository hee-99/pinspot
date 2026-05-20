import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/services/pin_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedPins();
    PinRefreshNotifier.instance.addListener(_loadSavedPins);
  }

  @override
  void dispose() {
    _tabController.dispose();
    PinRefreshNotifier.instance.removeListener(_loadSavedPins);
    super.dispose();
  }

  Future<void> _loadSavedPins() async {
    final pins = await PinService.getPins();
    if (mounted) setState(() => _savedPins = pins);
  }

  void _toggleLike(int index) => setState(() => _liked[index] = !(_liked[index] ?? false));
  void _toggleSave(int index) => setState(() => _saved[index] = !(_saved[index] ?? false));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'PINSPOT',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '팔로잉'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedList(
            posts: _allPosts,
            savedPins: _savedPins,
            liked: _liked,
            saved: _saved,
            onLike: _toggleLike,
            onSave: _toggleSave,
          ),
          _FeedList(
            posts: _allPosts.where((p) => p.isFollowing).toList(),
            savedPins: _savedPins,
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
            emptyMessage: '팔로잉한 핀플이 없습니다\n커뮤니티에서 핀플을 찾아보세요',
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
  final Map<int, bool> liked;
  final Map<int, bool> saved;
  final ValueChanged<int> onLike;
  final ValueChanged<int> onSave;
  final String? emptyMessage;

  const _FeedList({
    required this.posts,
    this.savedPins = const [],
    required this.liked,
    required this.saved,
    required this.onLike,
    required this.onSave,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavedPins = savedPins.isNotEmpty;
    if (posts.isEmpty && !hasSavedPins) {
      return Center(
        child: Text(
          emptyMessage ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        if (hasSavedPins) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(
              text: '내 핀',
              count: savedPins.length,
            ),
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
        if (hasSavedPins && posts.isNotEmpty)
          SliverToBoxAdapter(
            child: _SectionLabel(text: '핀플 피드'),
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
        const SliverPadding(padding: EdgeInsets.only(top: 12, bottom: 12)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final int? count;
  const _SectionLabel({required this.text, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700),
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
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
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
                      const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          pin.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(pin.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pin.description,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pin.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://maps.google.com/?daddr=${pin.lat},${pin.lng}&directionsmode=driving',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation, size: 13, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text(
                                '길찾기',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildPhoto() {
    if (pin.photoPath != null && !kIsWeb) {
      return Image.file(
        File(pin.photoPath!),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDE8D0), Color(0xFFCFDFC7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 28, color: AppTheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 4),
            Text(
              '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
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

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://maps.google.com/?daddr=${widget.pin.lat},${widget.pin.lng}&directionsmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('지도 앱을 열 수 없습니다'),
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
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
                markers: {
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(pin.lat, pin.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(14.0),
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
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 13, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              '내 핀',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(pin.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pin.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pin.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      pin.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
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
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                          label: const Text(
                            '길찾기',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: IconButton(
                          onPressed: _share,
                          icon: const Icon(
                            Icons.ios_share_outlined,
                            color: AppTheme.textPrimary,
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
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: post.avatarColor,
                    child: Text(
                      post.pinplerName[0],
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.pinplerName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '핀플',
                                style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          post.handle,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    post.timeAgo,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: _MapThumbnail(post: post),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                post.location,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              post.district,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: post.categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                post.category,
                                style: TextStyle(fontSize: 10, color: post.categoryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      _ActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_outline,
                        label: _fmt(post.likes + (isLiked ? 1 : 0)),
                        color: isLiked ? Colors.redAccent : AppTheme.textSecondary,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 14),
                      _ActionButton(
                        icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        label: _fmt(post.saves + (isSaved ? 1 : 0)),
                        color: isSaved ? AppTheme.primary : AppTheme.textSecondary,
                        onTap: onSave,
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => Share.share(
                          '📍 ${post.location} (${post.category})\n${post.district}\n핀스팟에서 발견한 숨겨진 장소!',
                          subject: post.location,
                        ),
                        child: const Icon(Icons.ios_share_outlined, size: 20, color: AppTheme.textSecondary),
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

  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://maps.google.com/?daddr=${widget.post.lat},${widget.post.lng}&directionsmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('지도 앱을 열 수 없습니다'),
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
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
                markers: {
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(post.lat, post.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(14.0),
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
                          Text(post.handle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      Text(post.timeAgo, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                      const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Text(post.district, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${post.lat.toStringAsFixed(4)}, ${post.lng.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                          label: const Text(
                            '길찾기',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: IconButton(
                          onPressed: _share,
                          icon: const Icon(Icons.ios_share_outlined, color: AppTheme.textPrimary, size: 20),
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
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDDE8D0), Color(0xFFCFDFC7)],
              ),
            ),
          ),
          CustomPaint(painter: _ThumbnailRoadPainter()),
          Align(
            alignment: Alignment(
              (post.pinDx * 2 - 1).clamp(-0.9, 0.9),
              (post.pinDy * 2 - 1).clamp(-0.9, 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.avatarColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: post.avatarColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: Text(
                          post.pinplerName[0],
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.location.length > 8 ? '${post.location.substring(0, 8)}…' : post.location,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
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

class _ThumbnailRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.50), paint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.45, size.height), paint);
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width * 0.5, size.height * 0.6), thin);
  }

  @override
  bool shouldRepaint(_ThumbnailRoadPainter old) => false;
}

// ─── 유틸 ──────────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${dt.month}/${dt.day}';
}
