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

// ─── 색상 토큰 · 워m 크림 라이트 모드 ─────────────────────────────────────────
const _kBg    = Color(0xFFF5F3EE);
const _kCard  = Color(0xFFFFFFFF);
const _kText1 = Color(0xFF1C1C1E);
const _kText2 = Color(0xFF6B7280);
const _kText3 = Color(0xFFC9C5BE);

BoxDecoration _cardDeco({double radius = 20}) => BoxDecoration(
  color: _kCard,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4))],
);

// ─── 핀플 피드 데이터 (상세 화면용 보존) ─────────────────────────────────────
class _FeedPost {
  final String pinplerName, handle, location, district, category, timeAgo;
  final Color avatarColor;
  final bool isFollowing;
  final int likes, saves;
  final double lat, lng;
  const _FeedPost({
    required this.pinplerName, required this.handle, required this.avatarColor,
    required this.isFollowing, required this.location, required this.district,
    required this.category, required this.timeAgo, required this.likes,
    required this.saves, required this.lat, required this.lng,
  });
}

const _allPosts = [
  _FeedPost(pinplerName: '산악대장', handle: '@mountainking', avatarColor: Color(0xFF4CAF50), isFollowing: true, location: '북한산 백운대 정상', district: '서울 강북구', category: '등산/명산', timeAgo: '23분 전', likes: 312, saves: 87, lat: 37.6558, lng: 126.9780),
  _FeedPost(pinplerName: '렌즈탐험가', handle: '@lensexplorer', avatarColor: Color(0xFFFF9800), isFollowing: false, location: '을지로 골목 벽화', district: '서울 중구', category: '사진 명소', timeAgo: '1시간 전', likes: 541, saves: 203, lat: 37.5663, lng: 126.9906),
  _FeedPost(pinplerName: '트레일러버', handle: '@traillover', avatarColor: Color(0xFF2196F3), isFollowing: true, location: '수락산 철모바위', district: '서울 노원구', category: '등산/명산', timeAgo: '5시간 전', likes: 189, saves: 55, lat: 37.6813, lng: 127.0681),
  _FeedPost(pinplerName: '도시폐허러', handle: '@urbanruin', avatarColor: Color(0xFF795548), isFollowing: false, location: '성수동 폐공장 B동', district: '서울 성동구', category: '폐허/어반', timeAgo: '8시간 전', likes: 763, saves: 341, lat: 37.5443, lng: 127.0557),
  _FeedPost(pinplerName: '새벽산행러', handle: '@dawnhiker', avatarColor: Color(0xFF9C27B0), isFollowing: true, location: '관악산 일출 포인트', district: '서울 관악구', category: '등산/명산', timeAgo: '어제', likes: 445, saves: 132, lat: 37.4413, lng: 126.9633),
];

// ─── 활동 모델 ────────────────────────────────────────────────────────────────
class _ActivityItem {
  final String userName, handle, mapEmoji, mapName, timeAgo, actionType;
  final Color avatarColor;
  final List<String> newPins;
  const _ActivityItem({
    required this.userName, required this.handle, required this.avatarColor,
    required this.mapEmoji, required this.mapName, required this.newPins,
    required this.timeAgo, required this.actionType,
  });
}

const _activityItems = [
  _ActivityItem(userName: '산악대장', handle: '@mountainking', avatarColor: Color(0xFF4CAF50), mapEmoji: '🏔', mapName: '서울 등산 코스', newPins: ['북한산 백운대 정상', '숨겨진 약수터'], timeAgo: '23분 전', actionType: 'added'),
  _ActivityItem(userName: '렌즈탐험가', handle: '@lensexplorer', avatarColor: Color(0xFFFF9800), mapEmoji: '📸', mapName: '을지로 사진 명소', newPins: ['골목 벽화', '빈티지 카페 거리'], timeAgo: '1시간 전', actionType: 'created'),
  _ActivityItem(userName: '트레일러버', handle: '@traillover', avatarColor: Color(0xFF2196F3), mapEmoji: '🌿', mapName: '수도권 트레일', newPins: ['수락산 철모바위'], timeAgo: '3시간 전', actionType: 'added'),
  _ActivityItem(userName: '새벽산행러', handle: '@dawnhiker', avatarColor: Color(0xFF9C27B0), mapEmoji: '🌅', mapName: '서울 일출 명소', newPins: ['관악산 일출 포인트', '남산 타워 뷰', '아차산 해맞이길'], timeAgo: '5시간 전', actionType: 'shared'),
];

// ─── 발견 지도 모델 ───────────────────────────────────────────────────────────
class _DiscoverMap {
  final String emoji, name, creator;
  final int pinCount, likes;
  final Color color;
  const _DiscoverMap({required this.emoji, required this.name, required this.creator, required this.pinCount, required this.likes, required this.color});
}

const _discoverMaps = [
  _DiscoverMap(emoji: '🥐', name: '서울 소금빵\n지도', creator: '@breadlover', pinCount: 21, likes: 2341, color: Color(0xFFF59E0B)),
  _DiscoverMap(emoji: '🌊', name: '한강 피크닉\n스팟', creator: '@riverside', pinCount: 15, likes: 1823, color: Color(0xFF0EA5E9)),
  _DiscoverMap(emoji: '📸', name: '을지로 사진\n명소', creator: '@lensexplorer', pinCount: 12, likes: 1204, color: Color(0xFFEC4899)),
  _DiscoverMap(emoji: '🏔', name: '북한산 등산\n코스', creator: '@mountainking', pinCount: 34, likes: 987, color: Color(0xFF16A34A)),
  _DiscoverMap(emoji: '☕', name: '홍대 카페\n투어', creator: '@cafeholic', pinCount: 28, likes: 876, color: Color(0xFF92400E)),
  _DiscoverMap(emoji: '🧇', name: '와플 맛집\n지도', creator: '@wafflelover', pinCount: 18, likes: 756, color: Color(0xFFF472B6)),
];

// ─── 피드 화면 ─────────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<PinModel> _savedPins = [];
  List<({PinModel pin, CommunityModel community})> _communityPins = [];
  bool _showFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    PinRefreshNotifier.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    PinRefreshNotifier.instance.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final pins = await PinService.getPins();
    final communityPins = await CommunityService.getJoinedCommunityPins();
    if (mounted) setState(() { _savedPins = pins; _communityPins = communityPins; });
  }

  Map<String, List<PinModel>> get _pinsByCategory {
    final map = <String, List<PinModel>>{};
    for (final pin in _savedPins) {
      (map[pin.category] ??= []).add(pin);
    }
    return map;
  }

  static const _greetings = ['오늘 어디 가세요? 🗺', '새로운 핀스팟을 찾아보세요 ✨', '오늘도 좋은 발견 하세요 😊'];

  @override
  Widget build(BuildContext context) {
    final categories = _pinsByCategory;
    final greeting = _greetings[DateTime.now().day % _greetings.length];

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── 앱바 ──────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true, snap: true,
            backgroundColor: _kBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            titleSpacing: 20,
            title: const Text('PINSPOT', style: TextStyle(fontWeight: FontWeight.w900, color: _kText1, letterSpacing: 1.2, fontSize: 17)),
            actions: [
              IconButton(icon: const Icon(Icons.search_rounded, color: _kText2, size: 22), onPressed: () {}),
              IconButton(icon: const Icon(Icons.notifications_outlined, color: _kText2, size: 22), onPressed: () {}),
              const SizedBox(width: 6),
            ],
          ),

          // ── 인사말 + 세그먼트 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(greeting, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _kText1, height: 1.2)),
                const SizedBox(height: 16),
                Row(children: [
                  _SegmentChip(label: '✨ 발견', selected: !_showFollowing, onTap: () => setState(() => _showFollowing = false)),
                  const SizedBox(width: 8),
                  _SegmentChip(label: '👥 팔로잉', selected: _showFollowing, onTap: () => setState(() => _showFollowing = true)),
                ]),
              ]),
            ),
          ),

          if (!_showFollowing) ...[
            // ── 내 지도 컬렉션 ────────────────────────────────────────────
            if (categories.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader(title: '내 지도 컬렉션', badge: '${_savedPins.length}핀')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ...categories.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _MyMapChip(category: e.key, count: e.value.length, onTap: () {}),
                      )),
                      _AddMapChip(onTap: () {}),
                    ],
                  ),
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: _EmptyMapsBanner(),
                ),
              ),

            // ── 이번 주 인기 지도 ──────────────────────────────────────────
            const SliverToBoxAdapter(child: _SectionHeader(title: '🔥 이번 주 인기 지도')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _DiscoverMapCard(
                    map: _discoverMaps[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _PinDetailScreen(post: _allPosts[i % _allPosts.length]))),
                  ),
                  childCount: _discoverMaps.length,
                ),
              ),
            ),
          ] else ...[
            // ── 팔로잉 활동 ────────────────────────────────────────────────
            const SliverToBoxAdapter(child: _SectionHeader(title: '팔로잉 활동')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ActivityCard(item: _activityItems[i]),
                ),
                childCount: _activityItems.length,
              ),
            ),

            if (_communityPins.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader(title: '커뮤니티 공유')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = _communityPins[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _CommunityPinCard(pin: item.pin, community: item.community),
                    );
                  },
                  childCount: _communityPins.length,
                ),
              ),
            ],

            if (_savedPins.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionHeader(title: '내 핀')),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _MyPinCard(pin: _savedPins[i]),
                  ),
                  childCount: _savedPins.length,
                ),
              ),
            ],

            if (_communityPins.isEmpty && _savedPins.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Center(
                    child: Column(children: [
                      const SizedBox(height: 40),
                      const Text('👥', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('아직 팔로잉한 핀플러가 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText2)),
                      const SizedBox(height: 8),
                      Text('지도 탐험가를 팔로우해서\n그들의 여정을 함께 해보세요!', style: const TextStyle(fontSize: 13, color: _kText3, height: 1.6), textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

// ─── 세그먼트 칩 ─────────────────────────────────────────────────────────────
class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kText1 : _kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected ? null : const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : _kText2)),
      ),
    );
  }
}

// ─── 섹션 헤더 ────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText1)),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
        const Spacer(),
        Text('더보기', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }
}

// ─── 내 지도 컬렉션 칩 ────────────────────────────────────────────────────────
class _MyMapChip extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;
  const _MyMapChip({required this.category, required this.count, required this.onTap});

  static const _emojiMap = {
    '등산': '🏔', '산': '🌲', '카페': '☕', '커피': '☕', '음식': '🍜',
    '먹': '🍴', '맛집': '🍽', '사진': '📸', '폐허': '🏚', '어반': '🏙',
    '바다': '🌊', '해변': '🏖', '공원': '🌿', '위험': '⚠️',
    '소금빵': '🥐', '와플': '🧇', '카레': '🍛', '라멘': '🍜',
  };

  String get _emoji {
    for (final e in _emojiMap.entries) {
      if (category.contains(e.key)) return e.value;
    }
    return '📍';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        decoration: _cardDeco(radius: 16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kText1),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
          Text('$count핀', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _AddMapChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMapChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 6),
          const Text('새 지도', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}

// ─── 빈 지도 배너 ─────────────────────────────────────────────────────────────
class _EmptyMapsBanner extends StatelessWidget {
  const _EmptyMapsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        const Text('🗺', style: TextStyle(fontSize: 34)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('나만의 지도를 만들어보세요!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          SizedBox(height: 4),
          Text('핀을 추가하면 카테고리별 지도가 자동 생성돼요',
              style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.45)),
        ])),
      ]),
    );
  }
}

// ─── 발견 지도 카드 ───────────────────────────────────────────────────────────
class _DiscoverMapCard extends StatelessWidget {
  final _DiscoverMap map;
  final VoidCallback? onTap;
  const _DiscoverMapCard({required this.map, this.onTap});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _cardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: map.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(children: [
              Center(child: Text(map.emoji, style: const TextStyle(fontSize: 44))),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: map.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('${map.pinCount}핀', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: map.color)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(map.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kText1, height: 1.3), maxLines: 2),
                const Spacer(),
                Row(children: [
                  Text(map.creator, style: const TextStyle(fontSize: 10, color: _kText2)),
                  const Spacer(),
                  const Icon(Icons.favorite_rounded, size: 11, color: Color(0xFFEF4444)),
                  const SizedBox(width: 3),
                  Text(_fmt(map.likes), style: const TextStyle(fontSize: 11, color: _kText2, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── 활동 카드 ────────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityCard({required this.item});

  String get _actionText {
    switch (item.actionType) {
      case 'created': return '새 지도를 만들었어요';
      case 'shared': return '커뮤니티에 공유했어요';
      default: return '지도에 핀을 추가했어요';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: item.avatarColor,
            child: Text(item.userName[0], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kText1)),
            Text(item.handle, style: const TextStyle(fontSize: 11, color: _kText2)),
          ])),
          Text(item.timeAgo, style: const TextStyle(fontSize: 11, color: _kText3)),
        ]),
        const SizedBox(height: 12),
        RichText(text: TextSpan(
          style: const TextStyle(fontSize: 13, color: _kText2, height: 1.45),
          children: [
            TextSpan(text: '${item.mapEmoji} '),
            TextSpan(text: '"${item.mapName}"', style: const TextStyle(fontWeight: FontWeight.w700, color: _kText1)),
            TextSpan(text: ' $_actionText'),
          ],
        )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: item.newPins.map((pin) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on, size: 11, color: AppColors.primary),
              const SizedBox(width: 3),
              Text(pin, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ]),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: const Row(children: [
              Text('지도 보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
            ]),
          ),
        ]),
      ]),
    );
  }
}

// ─── 내 핀 카드 (팔로잉 탭) ──────────────────────────────────────────────────
class _MyPinCard extends StatelessWidget {
  final PinModel pin;
  const _MyPinCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(),
        child: Row(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: pin.photoPath != null && !kIsWeb
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(pin.photoPath!), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.push_pin, color: AppColors.primary, size: 22)),
                  )
                : const Icon(Icons.push_pin_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TranslatableText(pin.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 11, color: AppColors.primary),
              const SizedBox(width: 2),
              Text(pin.category, style: const TextStyle(fontSize: 11, color: _kText2)),
            ]),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: const Text('보기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: community.color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(community.name, style: TextStyle(fontSize: 11, color: community.color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            TranslatableText(pin.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(pin.category, style: const TextStyle(fontSize: 11, color: _kText2)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _kText3),
        ]),
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
    final info = await LandmarkInfoService.fetchInfo(placeName: widget.pin.title, lat: widget.pin.lat, lng: widget.pin.lng);
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse('https://maps.google.com/?daddr=${widget.pin.lat},${widget.pin.lng}&directionsmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mapAppError), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _share() {
    final pin = widget.pin;
    Share.share('📍 ${pin.title} (${pin.category})\nhttps://maps.google.com/?q=${pin.lat},${pin.lng}', subject: pin.title);
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260, pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.neutral900,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(pin.lat, pin.lng), zoom: 15),
                onMapCreated: _mapCtrl.complete,
                zoomControlsEnabled: false, myLocationButtonEnabled: false,
                scrollGesturesEnabled: false, zoomGesturesEnabled: false,
                style: _mapStyle,
                markers: {Marker(markerId: const MarkerId('dest'), position: LatLng(pin.lat, pin.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('MY PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                  ),
                  const Spacer(),
                  Text(_timeAgo(pin.createdAt, context), style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                ]),
                const SizedBox(height: 16),
                TranslatableText(pin.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Expanded(child: Text('${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral500))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(pin.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                if (pin.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TranslatableText(pin.description, style: const TextStyle(fontSize: 14, color: AppColors.neutral500, height: 1.6)),
                ],
                if (pin.photoPath != null && !kIsWeb) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(pin.photoPath!), width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ],
                const SizedBox(height: 20),
                _LandmarkInfoWidget(isLoading: _isLoadingInfo, info: _landmarkInfo, onRefresh: _loadLandmarkInfo),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                      label: Text(AppLocalizations.of(context).directions,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                    height: 50, width: 50,
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neutral200)),
                    child: IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 핀 상세 화면 (발견 탭) ────────────────────────────────────────────────────
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
    final info = await LandmarkInfoService.fetchInfo(placeName: widget.post.location, lat: widget.post.lat, lng: widget.post.lng);
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse('https://maps.google.com/?daddr=${widget.post.lat},${widget.post.lng}&directionsmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).mapAppError), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _share() => Share.share(
    '📍 ${widget.post.location}\n${widget.post.district}\nhttps://maps.google.com/?q=${widget.post.lat},${widget.post.lng}',
    subject: widget.post.location,
  );

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260, pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.neutral900,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(post.lat, post.lng), zoom: 15),
                onMapCreated: _mapCtrl.complete,
                zoomControlsEnabled: false, myLocationButtonEnabled: false,
                scrollGesturesEnabled: false, zoomGesturesEnabled: false,
                style: _mapStyle,
                markers: {Marker(markerId: const MarkerId('dest'), position: LatLng(post.lat, post.lng),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: post.avatarColor,
                      child: Text(post.pinplerName[0], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post.pinplerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(post.handle, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                  ]),
                  const Spacer(),
                  Text(post.timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                ]),
                const SizedBox(height: 18),
                Text(post.location, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(post.district, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(post.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neutral200)),
                  child: Row(children: [
                    const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('${post.lat.toStringAsFixed(4)}, ${post.lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
                  ]),
                ),
                const SizedBox(height: 16),
                _LandmarkInfoWidget(isLoading: _isLoadingInfo, info: _landmarkInfo, onRefresh: _loadLandmarkInfo),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                      label: Text(AppLocalizations.of(context).directions,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
                    height: 50, width: 50,
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neutral200)),
                    child: IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20)),
                  ),
                ]),
              ]),
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
  const _LandmarkInfoWidget({required this.isLoading, required this.info, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.neutral200)),
        child: Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 10),
          Text(AppLocalizations.of(context).aiLoading, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
        ]),
      );
    }
    if (info == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context).aiInfo,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              child: Text(info!.sourceLabel, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            GestureDetector(onTap: onRefresh, child: const Icon(Icons.refresh, size: 16, color: AppColors.primary)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LandmarkRow(icon: Icons.history_edu_outlined, label: AppLocalizations.of(context).originHistory, text: info!.origin),
            const SizedBox(height: 10),
            _LandmarkRow(icon: Icons.place_outlined, label: AppLocalizations.of(context).highlights, text: info!.highlights),
            if (info!.bestTime != null && info!.bestTime!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _LandmarkRow(icon: Icons.calendar_today_outlined, label: AppLocalizations.of(context).bestTime, text: info!.bestTime!),
            ],
            if (info!.tip != null && info!.tip!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _LandmarkRow(icon: Icons.tips_and_updates_outlined, label: AppLocalizations.of(context).visitTip, text: info!.tip!),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  final IconData icon;
  final String label, text;
  const _LandmarkRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: AppColors.primary),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 2),
        TranslatableText(text, style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.5)),
      ])),
    ]);
  }
}

// ─── 유틸 ──────────────────────────────────────────────────────────────────────
String _timeAgo(DateTime dt, BuildContext context) => AppLocalizations.of(context).timeAgo(dt);
