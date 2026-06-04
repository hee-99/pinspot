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
import 'create_community_screen.dart';
import 'community_detail_screen.dart';

// ─── 색상 토큰 ─────────────────────────────────────────────────────────────────
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

// ─── 카테고리 필터 ─────────────────────────────────────────────────────────────
const _kCategories = [
  ('전체', ''), ('빵/디저트', '🥐'), ('카페', '☕'), ('등산/자연', '🏔'),
  ('사진명소', '📸'), ('음식', '🍜'), ('도시탐험', '🏙'), ('바다/강', '🌊'),
];

// ─── 발견 지도 데이터 ──────────────────────────────────────────────────────────
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

// ─── 활동 데이터 ───────────────────────────────────────────────────────────────
class _ActivityItem {
  final String userName, handle, mapEmoji, mapName, timeAgo, actionType;
  final Color avatarColor;
  final List<String> newPins;
  const _ActivityItem({required this.userName, required this.handle, required this.avatarColor, required this.mapEmoji, required this.mapName, required this.newPins, required this.timeAgo, required this.actionType});
}

const _activityItems = [
  _ActivityItem(userName: '산악대장', handle: '@mountainking', avatarColor: Color(0xFF4CAF50), mapEmoji: '🏔', mapName: '서울 등산 코스', newPins: ['북한산 백운대 정상', '숨겨진 약수터'], timeAgo: '23분 전', actionType: 'added'),
  _ActivityItem(userName: '렌즈탐험가', handle: '@lensexplorer', avatarColor: Color(0xFFFF9800), mapEmoji: '📸', mapName: '을지로 사진 명소', newPins: ['골목 벽화', '빈티지 카페 거리'], timeAgo: '1시간 전', actionType: 'created'),
  _ActivityItem(userName: '트레일러버', handle: '@traillover', avatarColor: Color(0xFF2196F3), mapEmoji: '🌿', mapName: '수도권 트레일', newPins: ['수락산 철모바위'], timeAgo: '3시간 전', actionType: 'added'),
  _ActivityItem(userName: '새벽산행러', handle: '@dawnhiker', avatarColor: Color(0xFF9C27B0), mapEmoji: '🌅', mapName: '서울 일출 명소', newPins: ['관악산 일출 포인트', '남산 타워 뷰'], timeAgo: '5시간 전', actionType: 'shared'),
];

// ─── 피드 포스트 데이터 (상세 화면용) ─────────────────────────────────────────
class _FeedPost {
  final String pinplerName, handle, location, district, category, timeAgo;
  final Color avatarColor;
  final int likes, saves;
  final double lat, lng;
  const _FeedPost({required this.pinplerName, required this.handle, required this.avatarColor, required this.location, required this.district, required this.category, required this.timeAgo, required this.likes, required this.saves, required this.lat, required this.lng});
}

const _allPosts = [
  _FeedPost(pinplerName: '산악대장', handle: '@mountainking', avatarColor: Color(0xFF4CAF50), location: '북한산 백운대 정상', district: '서울 강북구', category: '등산/명산', timeAgo: '23분 전', likes: 312, saves: 87, lat: 37.6558, lng: 126.9780),
  _FeedPost(pinplerName: '렌즈탐험가', handle: '@lensexplorer', avatarColor: Color(0xFFFF9800), location: '을지로 골목 벽화', district: '서울 중구', category: '사진 명소', timeAgo: '1시간 전', likes: 541, saves: 203, lat: 37.5663, lng: 126.9906),
  _FeedPost(pinplerName: '트레일러버', handle: '@traillover', avatarColor: Color(0xFF2196F3), location: '수락산 철모바위', district: '서울 노원구', category: '등산/명산', timeAgo: '5시간 전', likes: 189, saves: 55, lat: 37.6813, lng: 127.0681),
  _FeedPost(pinplerName: '도시폐허러', handle: '@urbanruin', avatarColor: Color(0xFF795548), location: '성수동 폐공장 B동', district: '서울 성동구', category: '폐허/어반', timeAgo: '8시간 전', likes: 763, saves: 341, lat: 37.5443, lng: 127.0557),
  _FeedPost(pinplerName: '새벽산행러', handle: '@dawnhiker', avatarColor: Color(0xFF9C27B0), location: '관악산 일출 포인트', district: '서울 관악구', category: '등산/명산', timeAgo: '어제', likes: 445, saves: 132, lat: 37.4413, lng: 126.9633),
];

// ─── 커뮤니티 화면 (3탭 통합) ─────────────────────────────────────────────────
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  List<CommunityModel> _communities = [];
  List<({PinModel pin, CommunityModel community})> _communityPins = [];
  List<PinModel> _savedPins = [];
  bool _loading = true;
  int _selectedCategoryIdx = 0;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    PinRefreshNotifier.instance.addListener(_load);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    PinRefreshNotifier.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final communities = await CommunityService.getCommunities();
    final communityPins = await CommunityService.getJoinedCommunityPins();
    final savedPins = await PinService.getPins();
    if (mounted) setState(() {
      _communities = communities;
      _communityPins = communityPins;
      _savedPins = savedPins;
      _loading = false;
    });
  }

  Map<String, List<PinModel>> get _pinsByCategory {
    final map = <String, List<PinModel>>{};
    for (final pin in _savedPins) {
      (map[pin.category] ??= []).add(pin);
    }
    return map;
  }

  bool _matchesCommunity(CommunityModel c) {
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!c.name.toLowerCase().contains(q) && !c.description.toLowerCase().contains(q)) return false;
    }
    if (_selectedCategoryIdx > 0) {
      final keyword = _kCategories[_selectedCategoryIdx].$1.toLowerCase().split('/').first;
      return c.name.toLowerCase().contains(keyword) || c.description.toLowerCase().contains(keyword);
    }
    return true;
  }

  List<CommunityModel> get _joined => _communities.where((c) => c.isJoined && _matchesCommunity(c)).toList();
  List<CommunityModel> get _explore => _communities.where((c) => !c.isJoined && !c.isPrivate && _matchesCommunity(c)).toList();
  CommunityModel? get _featured {
    final pool = _communities.where((c) => !c.isJoined && !c.isPrivate).toList();
    if (pool.isEmpty) return null;
    return pool.reduce((a, b) => a.pinCount > b.pinCount ? a : b);
  }

  Future<void> _openCreate() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityScreen()));
    _load();
  }

  Future<void> _openDetail(CommunityModel c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: c)));
    _load();
  }

  Future<void> _toggleJoin(CommunityModel c) async {
    await CommunityService.toggleJoin(c.id);
    _load();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) { _searchCtrl.clear(); _searchQuery = ''; }
      else { Future.delayed(const Duration(milliseconds: 80), () => _searchFocus.requestFocus()); }
    });
  }

  Future<void> _showJoinByCode() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CodeJoinSheet(
        ctrl: ctrl,
        onJoin: (code) async {
          final community = await CommunityService.joinByCode(code);
          if (!mounted) return;
          Navigator.pop(context);
          if (community != null) {
            _load();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${community.emoji} ${community.name}에 참여했어요!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: community.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          } else {
            const SnackBar(content: Text('코드를 찾을 수 없어요.'), behavior: SnackBarBehavior.floating);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            floating: true, snap: true,
            backgroundColor: _kBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            titleSpacing: 20,
            title: _showSearch
                ? TextField(
                    controller: _searchCtrl, focusNode: _searchFocus,
                    style: const TextStyle(fontSize: 15, color: _kText1),
                    decoration: const InputDecoration(hintText: '커뮤니티 검색', hintStyle: TextStyle(color: _kText3, fontSize: 15), border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : const Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kText1)),
            actions: [
              IconButton(icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, color: _kText2, size: 22), onPressed: _toggleSearch),
              IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24), onPressed: _openCreate),
              const SizedBox(width: 6),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: _kCard,
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: _kText1,
                  unselectedLabelColor: _kText3,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  dividerColor: _kBg,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  tabs: const [Tab(text: '👥 그룹'), Tab(text: '✨ 발견'), Tab(text: '🔔 팔로잉')],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _GroupsTab(
              communities: _communities, loading: _loading,
              joined: _joined, explore: _explore, featured: _featured,
              selectedCategoryIdx: _selectedCategoryIdx,
              searchQuery: _searchQuery,
              onCategorySelect: (i) => setState(() => _selectedCategoryIdx = i),
              onOpenCreate: _openCreate, onJoinByCode: _showJoinByCode,
              onOpenDetail: _openDetail, onToggleJoin: _toggleJoin,
            ),
            _DiscoverTab(savedPins: _savedPins, pinsByCategory: _pinsByCategory),
            _FollowingTab(communityPins: _communityPins),
          ],
        ),
      ),
    );
  }
}

// ─── 발견 탭 ──────────────────────────────────────────────────────────────────
class _DiscoverTab extends StatelessWidget {
  final List<PinModel> savedPins;
  final Map<String, List<PinModel>> pinsByCategory;
  const _DiscoverTab({required this.savedPins, required this.pinsByCategory});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 내 지도 컬렉션
        if (pinsByCategory.isNotEmpty) ...[
          const SliverToBoxAdapter(child: _SectionHeader(title: '내 지도 컬렉션')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...pinsByCategory.entries.map((e) => Padding(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _EmptyMapsBanner(),
            ),
          ),

        // 이번 주 인기 지도
        const SliverToBoxAdapter(child: _SectionHeader(title: '🔥 이번 주 인기 지도')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _FeaturedMapCard(
              map: _discoverMaps[0],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _PinDetailScreen(post: _allPosts[0]))),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _DiscoverMapCard(
                map: _discoverMaps[i + 1],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _PinDetailScreen(post: _allPosts[(i + 1) % _allPosts.length]))),
              ),
              childCount: _discoverMaps.length - 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 그룹 탭 ──────────────────────────────────────────────────────────────────
class _GroupsTab extends StatelessWidget {
  final List<CommunityModel> communities, joined, explore;
  final CommunityModel? featured;
  final bool loading;
  final int selectedCategoryIdx;
  final String searchQuery;
  final ValueChanged<int> onCategorySelect;
  final VoidCallback onOpenCreate, onJoinByCode;
  final ValueChanged<CommunityModel> onOpenDetail, onToggleJoin;

  const _GroupsTab({
    required this.communities, required this.joined, required this.explore,
    required this.featured, required this.loading, required this.selectedCategoryIdx,
    required this.searchQuery, required this.onCategorySelect,
    required this.onOpenCreate, required this.onJoinByCode,
    required this.onOpenDetail, required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 핫 배너
        if (featured != null && searchQuery.isEmpty && selectedCategoryIdx == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _HotBanner(community: featured!, onTap: () => onOpenDetail(featured!), onJoin: () => onToggleJoin(featured!)),
          ),

        // 빠른 액션
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Expanded(child: _QuickActionCard(icon: Icons.add_circle_rounded, label: '커뮤니티 만들기', description: '나만의 지도 공유방', color: AppColors.primary, onTap: onOpenCreate)),
            const SizedBox(width: 12),
            Expanded(child: _QuickActionCard(icon: Icons.vpn_key_rounded, label: '코드로 참여', description: '초대코드 6자리 입력', color: const Color(0xFF0284C7), onTap: onJoinByCode)),
          ]),
        ),

        // 카테고리 필터
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (label, emoji) = _kCategories[i];
                final selected = selectedCategoryIdx == i;
                return GestureDetector(
                  onTap: () => onCategorySelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? _kText1 : _kCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selected ? null : const [BoxShadow(color: Color(0x09000000), blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: Text(emoji.isEmpty ? label : '$emoji $label',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : _kText2)),
                  ),
                );
              },
            ),
          ),
        ),

        // 검색 결과 없음
        if (searchQuery.isNotEmpty && joined.isEmpty && explore.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(children: [
              Icon(Icons.search_off_rounded, size: 56, color: _kText3),
              const SizedBox(height: 12),
              Text('"$searchQuery" 결과가 없어요', style: const TextStyle(color: _kText2, fontSize: 14)),
            ]),
          ),

        // 내 커뮤니티
        if (joined.isNotEmpty) ...[
          _buildSectionHeader('내 커뮤니티', joined.length),
          SizedBox(
            height: 144,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: joined.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _JoinedCard(community: joined[i], onTap: () => onOpenDetail(joined[i])),
            ),
          ),
        ],

        // 둘러보기
        _buildSectionHeader(
          joined.isEmpty ? '커뮤니티 둘러보기' : '둘러보기',
          explore.length,
          sub: '마음에 드는 커뮤니티에 참여해보세요',
        ),

        if (explore.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('모든 커뮤니티에 참여 중이에요!', style: TextStyle(color: _kText2, fontSize: 14)),
            ]),
          )
        else
          ...explore.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, e.key < explore.length - 1 ? 14 : 100),
            child: _ExploreCard(community: e.value, onTap: () => onOpenDetail(e.value), onJoin: () => onToggleJoin(e.value)),
          )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, {String? sub}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText1)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        const Text('더보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
      if (sub != null) ...[const SizedBox(height: 4), Text(sub, style: const TextStyle(fontSize: 12, color: _kText2))],
    ]),
  );
}

// ─── 팔로잉 탭 ────────────────────────────────────────────────────────────────
class _FollowingTab extends StatelessWidget {
  final List<({PinModel pin, CommunityModel community})> communityPins;
  const _FollowingTab({required this.communityPins});

  @override
  Widget build(BuildContext context) {
    final bool hasPins = communityPins.isNotEmpty;
    final bool hasActivity = _activityItems.isNotEmpty;

    if (!hasPins && !hasActivity) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('👥', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text('아직 팔로잉한 핀플러가 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText2)),
        const SizedBox(height: 8),
        const Text('지도 탐험가를 팔로우하고\n그들의 여정을 함께 해보세요!', style: TextStyle(fontSize: 13, color: _kText3, height: 1.6), textAlign: TextAlign.center),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // 활동 스트림
        const _FollowingHeader(title: '팔로잉 활동'),
        ..._activityItems.map((item) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _ActivityCard(item: item),
        )),

        // 커뮤니티 공유 핀
        if (hasPins) ...[
          const _FollowingHeader(title: '커뮤니티 공유'),
          ...communityPins.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, e.key < communityPins.length - 1 ? 12 : 0),
            child: _CommunityPinCard(pin: e.value.pin, community: e.value.community),
          )),
        ],
      ],
    );
  }
}

class _FollowingHeader extends StatelessWidget {
  final String title;
  const _FollowingHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText1)),
    );
  }
}

// ─── 섹션 헤더 ────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText1)),
        const Spacer(),
        const Text('더보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }
}

// ─── 발견 위젯 ────────────────────────────────────────────────────────────────
class _FeaturedMapCard extends StatelessWidget {
  final _DiscoverMap map;
  final VoidCallback? onTap;
  const _FeaturedMapCard({required this.map, this.onTap});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 156, decoration: _cardDeco(), clipBehavior: Clip.antiAlias,
        child: Row(children: [
          Container(width: 128, color: map.color.withValues(alpha: 0.12),
              child: Center(child: Text(map.emoji, style: const TextStyle(fontSize: 58)))),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: map.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('✨ 이번 주 픽', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: map.color)),
              ),
              const SizedBox(height: 10),
              Text(map.name.replaceAll('\n', ' '), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kText1, height: 1.25), maxLines: 2),
              const Spacer(),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: map.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('${map.pinCount}핀', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: map.color)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.favorite_rounded, size: 11, color: Color(0xFFEF4444)),
                const SizedBox(width: 3),
                Text(_fmt(map.likes), style: const TextStyle(fontSize: 11, color: _kText2, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 5),
              Text(map.creator, style: const TextStyle(fontSize: 11, color: _kText2)),
            ]),
          )),
        ]),
      ),
    );
  }
}

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
            decoration: BoxDecoration(color: map.color.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Stack(children: [
              Center(child: Text(map.emoji, style: const TextStyle(fontSize: 44))),
              Positioned(top: 10, right: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: map.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${map.pinCount}핀', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: map.color)),
              )),
            ]),
          ),
          Expanded(child: Padding(
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
          )),
        ]),
      ),
    );
  }
}

class _MyMapChip extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;
  const _MyMapChip({required this.category, required this.count, required this.onTap});

  static const _emojiMap = {'등산': '🏔', '산': '🌲', '카페': '☕', '커피': '☕', '음식': '🍜', '먹': '🍴', '맛집': '🍽', '사진': '📸', '폐허': '🏚', '어반': '🏙', '바다': '🌊', '해변': '🏖', '공원': '🌿', '위험': '⚠️', '소금빵': '🥐', '와플': '🧇'};
  String get _emoji { for (final e in _emojiMap.entries) { if (category.contains(e.key)) return e.value; } return '📍'; }

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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kText1), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
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
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18)),
          const SizedBox(height: 6),
          const Text('새 지도', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _EmptyMapsBanner extends StatelessWidget {
  const _EmptyMapsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: const Row(children: [
        Text('🗺', style: TextStyle(fontSize: 34)),
        SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('나만의 지도를 만들어보세요!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          SizedBox(height: 4),
          Text('핀을 추가하면 카테고리별 지도가 자동 생성돼요', style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.45)),
        ])),
      ]),
    );
  }
}

// ─── 그룹 위젯 ────────────────────────────────────────────────────────────────
class _HotBanner extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap, onJoin;
  const _HotBanner({required this.community, required this.onTap, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 30)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('🔥 이번 주 인기', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
            const SizedBox(height: 6),
            Text(community.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText1), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on, size: 12, color: color),
              const SizedBox(width: 3),
              Text('${_fmt(community.pinCount)}핀', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.people, size: 12, color: _kText2),
              const SizedBox(width: 3),
              Text('${_fmt(community.memberCount)}명', style: const TextStyle(fontSize: 12, color: _kText2)),
            ]),
          ])),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
              child: const Text('참여', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.description, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 19)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 11, color: _kText2)),
        ]),
      ),
    );
  }
}

class _JoinedCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  const _JoinedCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104, decoration: _cardDeco(radius: 18), clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Expanded(flex: 3, child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
            child: community.imagePath != null && !kIsWeb
                ? Image.file(File(community.imagePath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(community.emoji, style: const TextStyle(fontSize: 30))))
                : Center(child: Text(community.emoji, style: const TextStyle(fontSize: 32))),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(community.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kText1), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on, size: 10, color: color),
                const SizedBox(width: 2),
                Text('${_fmt(community.pinCount)}핀', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap, onJoin;
  const _ExploreCard({required this.community, required this.onTap, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108, decoration: _cardDeco(), clipBehavior: Clip.antiAlias,
        child: Row(children: [
          Container(
            width: 88, color: color.withValues(alpha: 0.13),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              community.imagePath != null && !kIsWeb
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(community.imagePath!), width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(community.emoji, style: const TextStyle(fontSize: 30))))
                  : Text(community.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)),
                child: Text('${_fmt(community.pinCount)}핀', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
              ),
            ]),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(community.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText1), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (community.isPrivate) Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                  child: const Text('비공개', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                ),
              ]),
              const SizedBox(height: 4),
              Text(community.description, style: const TextStyle(fontSize: 12, color: _kText2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(children: [
                Icon(Icons.people_outline, size: 12, color: _kText2),
                const SizedBox(width: 3),
                Text('${_fmt(community.memberCount)}명', style: const TextStyle(fontSize: 11, color: _kText2)),
                const Spacer(),
                GestureDetector(
                  onTap: onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]),
                    child: const Text('참여', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─── 팔로잉 위젯 ──────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityCard({required this.item});

  String get _actionText { switch (item.actionType) { case 'created': return '새 지도를 만들었어요'; case 'shared': return '커뮤니티에 공유했어요'; default: return '지도에 핀을 추가했어요'; } }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: item.avatarColor, child: Text(item.userName[0], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
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

class _CommunityPinCard extends StatelessWidget {
  final PinModel pin;
  final CommunityModel community;
  const _CommunityPinCard({required this.pin, required this.community});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SavedPinDetailScreen(pin: pin))),
      child: Container(
        padding: const EdgeInsets.all(14), decoration: _cardDeco(),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: community.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(community.name, style: TextStyle(fontSize: 11, color: community.color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            TranslatableText(pin.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText1), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  void initState() { super.initState(); _loadLandmarkInfo(); _loadMapStyle(); }

  Future<void> _loadMapStyle() async {
    try { final style = await rootBundle.loadString('assets/map_style.json'); if (mounted) setState(() => _mapStyle = style); } catch (_) {}
  }

  Future<void> _loadLandmarkInfo() async {
    final info = await LandmarkInfoService.fetchInfo(placeName: widget.pin.title, lat: widget.pin.lat, lng: widget.pin.lng);
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse('https://maps.google.com/?daddr=${widget.pin.lat},${widget.pin.lng}&directionsmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _share() => Share.share('📍 ${widget.pin.title} (${widget.pin.category})\nhttps://maps.google.com/?q=${widget.pin.lat},${widget.pin.lng}', subject: widget.pin.title);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pin = widget.pin;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260, pinned: true,
          backgroundColor: AppColors.surface, foregroundColor: AppColors.neutral900, elevation: 0,
          flexibleSpace: FlexibleSpaceBar(background: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(pin.lat, pin.lng), zoom: 15),
            onMapCreated: _mapCtrl.complete, zoomControlsEnabled: false, myLocationButtonEnabled: false,
            scrollGesturesEnabled: false, zoomGesturesEnabled: false, style: _mapStyle,
            markers: {Marker(markerId: const MarkerId('dest'), position: LatLng(pin.lat, pin.lng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))},
          )),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on, size: 13, color: AppColors.primary), SizedBox(width: 4), Text('MY PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))])),
              const Spacer(),
              Text(_timeAgo(pin.createdAt, context), style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
            ]),
            const SizedBox(height: 16),
            TranslatableText(pin.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.primary),
              const SizedBox(width: 3),
              Expanded(child: Text('${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 13, color: AppColors.neutral500))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(pin.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
            ]),
            if (pin.description.isNotEmpty) ...[const SizedBox(height: 16), TranslatableText(pin.description, style: const TextStyle(fontSize: 14, color: AppColors.neutral500, height: 1.6))],
            if (pin.photoPath != null && !kIsWeb) ...[const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(pin.photoPath!), width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))],
            const SizedBox(height: 20),
            _LandmarkInfoWidget(isLoading: _isLoadingInfo, info: _landmarkInfo, onRefresh: _loadLandmarkInfo),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _openNavigation, icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                label: Text(l.directions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
              const SizedBox(width: 10),
              Container(height: 50, width: 50, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neutral200)),
                child: IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20))),
            ]),
          ]),
        )),
      ]),
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
  void initState() { super.initState(); _loadLandmarkInfo(); _loadMapStyle(); }

  Future<void> _loadMapStyle() async {
    try { final style = await rootBundle.loadString('assets/map_style.json'); if (mounted) setState(() => _mapStyle = style); } catch (_) {}
  }

  Future<void> _loadLandmarkInfo() async {
    final info = await LandmarkInfoService.fetchInfo(placeName: widget.post.location, lat: widget.post.lat, lng: widget.post.lng);
    if (mounted) setState(() { _landmarkInfo = info; _isLoadingInfo = false; });
  }

  Future<void> _openNavigation() async {
    final uri = Uri.parse('https://maps.google.com/?daddr=${widget.post.lat},${widget.post.lng}&directionsmode=driving');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _share() => Share.share('📍 ${widget.post.location}\n${widget.post.district}\nhttps://maps.google.com/?q=${widget.post.lat},${widget.post.lng}', subject: widget.post.location);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final post = widget.post;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260, pinned: true,
          backgroundColor: AppColors.surface, foregroundColor: AppColors.neutral900, elevation: 0,
          flexibleSpace: FlexibleSpaceBar(background: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(post.lat, post.lng), zoom: 15),
            onMapCreated: _mapCtrl.complete, zoomControlsEnabled: false, myLocationButtonEnabled: false,
            scrollGesturesEnabled: false, zoomGesturesEnabled: false, style: _mapStyle,
            markers: {Marker(markerId: const MarkerId('dest'), position: LatLng(post.lat, post.lng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))},
          )),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 20, backgroundColor: post.avatarColor, child: Text(post.pinplerName[0], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
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
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(post.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 16),
            _LandmarkInfoWidget(isLoading: _isLoadingInfo, info: _landmarkInfo, onRefresh: _loadLandmarkInfo),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _openNavigation, icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                label: Text(l.directions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
              const SizedBox(width: 10),
              Container(height: 50, width: 50, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neutral200)),
                child: IconButton(onPressed: _share, icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20))),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ─── AI 정보 위젯 ──────────────────────────────────────────────────────────────
class _LandmarkInfoWidget extends StatelessWidget {
  final bool isLoading;
  final LandmarkInfo? info;
  final VoidCallback onRefresh;
  const _LandmarkInfoWidget({required this.isLoading, required this.info, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (isLoading) return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.neutral200)),
      child: Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        const SizedBox(width: 10),
        Text(l.aiLoading, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
      ]),
    );
    if (info == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.neutral200),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(l.aiInfo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              child: Text(info!.sourceLabel, style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600))),
            const Spacer(),
            GestureDetector(onTap: onRefresh, child: const Icon(Icons.refresh, size: 16, color: AppColors.primary)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LandmarkRow(icon: Icons.history_edu_outlined, label: l.originHistory, text: info!.origin),
            const SizedBox(height: 10),
            _LandmarkRow(icon: Icons.place_outlined, label: l.highlights, text: info!.highlights),
            if (info!.bestTime != null && info!.bestTime!.isNotEmpty) ...[const SizedBox(height: 10), _LandmarkRow(icon: Icons.calendar_today_outlined, label: l.bestTime, text: info!.bestTime!)],
            if (info!.tip != null && info!.tip!.isNotEmpty) ...[const SizedBox(height: 10), _LandmarkRow(icon: Icons.tips_and_updates_outlined, label: l.visitTip, text: info!.tip!)],
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

// ─── 코드로 참여 시트 ─────────────────────────────────────────────────────────
class _CodeJoinSheet extends StatefulWidget {
  final TextEditingController ctrl;
  final Future<void> Function(String code) onJoin;
  const _CodeJoinSheet({required this.ctrl, required this.onJoin});
  @override
  State<_CodeJoinSheet> createState() => _CodeJoinSheetState();
}

class _CodeJoinSheetState extends State<_CodeJoinSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Container(
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 20), decoration: BoxDecoration(color: _kText3, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 22)),
            const SizedBox(width: 14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('코드로 커뮤니티 참여', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kText1)),
              Text('초대 코드 6자리를 입력하세요', style: TextStyle(fontSize: 12, color: _kText2)),
            ]),
          ]),
          const SizedBox(height: 24),
          TextField(
            controller: widget.ctrl, autofocus: true, maxLength: 6,
            textCapitalization: TextCapitalization.characters, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 12, color: AppColors.primary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              counterText: '', hintText: '• • • • • •',
              hintStyle: const TextStyle(fontSize: 22, letterSpacing: 8, color: _kText3),
              filled: true, fillColor: AppColors.primary.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (widget.ctrl.text.trim().length == 6 && !_loading)
                  ? () async { setState(() => _loading = true); await widget.onJoin(widget.ctrl.text.trim().toUpperCase()); }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: _kText3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('참여하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ─── 유틸 ──────────────────────────────────────────────────────────────────────
String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
String _timeAgo(DateTime dt, BuildContext context) => AppLocalizations.of(context).timeAgo(dt);
