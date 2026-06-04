import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/community_service.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';

// ─── 색상 토큰 (피드와 동일 · 워m 크림) ───────────────────────────────────────
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

// ─── 카테고리 필터 데이터 ─────────────────────────────────────────────────────
const _kCategories = [
  ('전체', ''),
  ('빵/디저트', '🥐'),
  ('카페', '☕'),
  ('등산/자연', '🏔'),
  ('사진명소', '📸'),
  ('음식', '🍜'),
  ('도시탐험', '🏙'),
  ('바다/강', '🌊'),
];

// ─── 커뮤니티 화면 ────────────────────────────────────────────────────────────
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityModel> _communities = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _showSearch = false;
  int _selectedCategoryIdx = 0;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await CommunityService.getCommunities();
    if (mounted) setState(() { _communities = list; _loading = false; });
  }

  bool _matches(CommunityModel c) {
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

  List<CommunityModel> get _joined =>
      _communities.where((c) => c.isJoined && _matches(c)).toList();
  List<CommunityModel> get _explore =>
      _communities.where((c) => !c.isJoined && !c.isPrivate && _matches(c)).toList();

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
      if (!_showSearch) {
        _searchCtrl.clear();
        _searchQuery = '';
      } else {
        Future.delayed(const Duration(milliseconds: 80), () => _searchFocus.requestFocus());
      }
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('코드를 찾을 수 없어요. 다시 확인해주세요.'),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
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
            title: _showSearch
                ? TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    style: const TextStyle(fontSize: 15, color: _kText1),
                    decoration: InputDecoration(
                      hintText: '커뮤니티 검색',
                      hintStyle: const TextStyle(color: _kText3, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : const Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kText1)),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, color: _kText2, size: 22),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                tooltip: '커뮤니티 만들기',
                onPressed: _openCreate,
              ),
              const SizedBox(width: 6),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else ...[
            // ── 이번 주 핫 커뮤니티 배너 ────────────────────────────────────
            if (featured != null && _searchQuery.isEmpty && _selectedCategoryIdx == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _HotBanner(community: featured, onTap: () => _openDetail(featured), onJoin: () => _toggleJoin(featured)),
                ),
              ),

            // ── 빠른 액션 ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(child: _QuickActionCard(
                    icon: Icons.add_circle_rounded, label: '커뮤니티 만들기',
                    description: '나만의 지도 공유방', color: AppColors.primary, onTap: _openCreate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickActionCard(
                    icon: Icons.vpn_key_rounded, label: '코드로 참여',
                    description: '초대코드 6자리 입력', color: const Color(0xFF0284C7), onTap: _showJoinByCode,
                  )),
                ]),
              ),
            ),

            // ── 카테고리 필터 칩 ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
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
                      final selected = _selectedCategoryIdx == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? _kText1 : _kCard,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected ? null : const [BoxShadow(color: Color(0x09000000), blurRadius: 6, offset: Offset(0, 2))],
                          ),
                          child: Text(
                            emoji.isEmpty ? label : '$emoji $label',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : _kText2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── 검색 결과 없음 ─────────────────────────────────────────────
            if (_searchQuery.isNotEmpty && _joined.isEmpty && _explore.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(children: [
                    Icon(Icons.search_off_rounded, size: 56, color: _kText3),
                    const SizedBox(height: 12),
                    Text('"$_searchQuery" 결과가 없어요', style: const TextStyle(color: _kText2, fontSize: 14)),
                  ]),
                ),
              ),

            // ── 내 커뮤니티 ───────────────────────────────────────────────
            if (_joined.isNotEmpty) ...[
              _sectionHeader('내 커뮤니티', _joined.length),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    itemCount: _joined.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _JoinedCard(community: _joined[i], onTap: () => _openDetail(_joined[i])),
                  ),
                ),
              ),
            ],

            // ── 둘러보기 ─────────────────────────────────────────────────
            _sectionHeader(
              _joined.isEmpty ? '커뮤니티 둘러보기' : '둘러보기',
              _explore.length,
              sub: '마음에 드는 커뮤니티에 참여해보세요',
            ),

            if (_explore.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(children: [
                    const Text('🎉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('모든 커뮤니티에 참여 중이에요!', style: TextStyle(color: _kText2, fontSize: 14)),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ExploreCard(
                        community: _explore[i],
                        onTap: () => _openDetail(_explore[i]),
                        onJoin: () => _toggleJoin(_explore[i]),
                      ),
                    ),
                    childCount: _explore.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count, {String? sub}) => SliverToBoxAdapter(
    child: Padding(
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
          Text('더보기', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 12, color: _kText2)),
        ],
      ]),
    ),
  );
}

// ─── 이번 주 핫 배너 ─────────────────────────────────────────────────────────
class _HotBanner extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  const _HotBanner({required this.community, required this.onTap, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('🔥 이번 주 인기', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
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
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Text('참여', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── 빠른 액션 카드 ───────────────────────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 11, color: _kText2)),
        ]),
      ),
    );
  }
}

// ─── 내 커뮤니티 가로 카드 ────────────────────────────────────────────────────
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
        width: 130,
        decoration: _cardDeco(radius: 20),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 이모지 배너
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
            ),
            child: _communityBannerContent(community, color),
          ),
          // 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(community.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText1, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(children: [
                  Icon(Icons.location_on, size: 11, color: color),
                  const SizedBox(width: 2),
                  Text('${_fmt(community.pinCount)}핀', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── 둘러보기 카드 ────────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  const _ExploreCard({required this.community, required this.onTap, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: _cardDeco(),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 이모지 배너 (라이트 배경)
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08)),
            child: Stack(children: [
              Positioned(
                right: -8, top: -8,
                child: Opacity(opacity: 0.08, child: Text(community.emoji, style: const TextStyle(fontSize: 80))),
              ),
              Center(child: _communityBannerContent(community, color)),
            ]),
          ),
          // 정보 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(community.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText1, letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Text(community.description, style: const TextStyle(fontSize: 12, color: _kText2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                // 핀 수 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.location_on, size: 11, color: color),
                    const SizedBox(width: 3),
                    Text('${_fmt(community.pinCount)}핀', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(width: 8),
                Icon(Icons.people_outline, size: 13, color: _kText2),
                const SizedBox(width: 3),
                Text(_fmt(community.memberCount), style: const TextStyle(fontSize: 11, color: _kText2)),
                if (community.isPrivate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('비공개', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Text('참여', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── 커뮤니티 배너 콘텐츠 헬퍼 ───────────────────────────────────────────────
Widget _communityBannerContent(CommunityModel community, Color color) {
  if (community.imagePath != null && !kIsWeb) {
    return SizedBox.expand(
      child: Image.file(File(community.imagePath!), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: Text(community.emoji, style: const TextStyle(fontSize: 32)))),
    );
  }
  return Center(child: Text(community.emoji, style: const TextStyle(fontSize: 32)));
}

// ─── 코드로 참여 바텀시트 ─────────────────────────────────────────────────────
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
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(color: _kText3, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('코드로 커뮤니티 참여', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kText1)),
              Text('초대 코드 6자리를 입력하세요', style: TextStyle(fontSize: 12, color: _kText2)),
            ]),
          ]),
          const SizedBox(height: 24),
          TextField(
            controller: widget.ctrl,
            autofocus: true, maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 12, color: AppColors.primary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              hintStyle: const TextStyle(fontSize: 22, letterSpacing: 8, color: _kText3),
              filled: true,
              fillColor: AppColors.primary.withValues(alpha: 0.05),
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
                  ? () async {
                      setState(() => _loading = true);
                      await widget.onJoin(widget.ctrl.text.trim().toUpperCase());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: _kText3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('참여하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
