import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/community_service.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';

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
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q);
  }

  List<CommunityModel> get _joined =>
      _communities.where((c) => c.isJoined && _matches(c)).toList();
  List<CommunityModel> get _explore =>
      _communities.where((c) => !c.isJoined && !c.isPrivate && _matches(c)).toList();

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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('코드를 찾을 수 없어요. 다시 확인해주세요.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: CustomScrollView(
        slivers: [
          // ── 앱바 ─────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            floating: true,
            snap: true,
            title: _showSearch
                ? TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '커뮤니티 검색',
                      hintStyle: TextStyle(color: AppColors.neutral500.withValues(alpha: 0.6), fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : const Text('커뮤니티',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search_rounded,
                    color: AppColors.neutral900, size: 22),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                tooltip: '커뮤니티 만들기',
                onPressed: _openCreate,
              ),
              const SizedBox(width: 4),
            ],
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            // ── 빠른 액션 ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_circle_rounded,
                        label: '커뮤니티 만들기',
                        description: '나만의 스폿 공유방',
                        color: AppColors.primary,
                        onTap: _openCreate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.vpn_key_rounded,
                        label: '코드로 참여',
                        description: '초대코드 6자리 입력',
                        color: const Color(0xFF0284C7),
                        onTap: _showJoinByCode,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 검색 결과 없음 ─────────────────────────────────────────────
            if (_searchQuery.isNotEmpty && _joined.isEmpty && _explore.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 56,
                          color: AppColors.neutral500.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('"$_searchQuery" 결과가 없어요',
                          style: const TextStyle(color: AppColors.neutral500, fontSize: 14)),
                    ],
                  ),
                ),
              ),

            // ── 내 커뮤니티 ───────────────────────────────────────────────
            if (_joined.isNotEmpty) ...[
              _sectionHeader('내 커뮤니티', _joined.length),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: _joined.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _JoinedCard(
                      community: _joined[i],
                      onTap: () => _openDetail(_joined[i]),
                    ),
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
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 52,
                          color: AppColors.neutral500.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('모든 커뮤니티에 참여 중이에요 🎉',
                          style: TextStyle(color: AppColors.neutral500, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
          ],
        ],
      ),
    ),
  );
}

// ── 빠른 액션 카드 ─────────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon, required this.label, required this.description,
    required this.color, required this.onTap,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
          ],
        ),
      ),
    );
  }
}

// ── 내 커뮤니티 가로 카드 ───────────────────────────────────────────────────────
class _JoinedCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;

  const _JoinedCard({required this.community, required this.onTap});

  Widget _banner(Color color) {
    if (community.imagePath != null && !kIsWeb) {
      return SizedBox(
        height: 70, width: double.infinity,
        child: Image.file(
          File(community.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiBanner(color),
        ),
      );
    }
    return _emojiBanner(color);
  }

  Widget _emojiBanner(Color color) => Container(
    height: 70,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
      ),
    ),
    child: Center(child: Text(community.emoji, style: const TextStyle(fontSize: 36))),
  );

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _banner(color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.people, size: 12, color: color),
                        const SizedBox(width: 3),
                        Text(_fmt(community.memberCount),
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 둘러보기 카드 ─────────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _ExploreCard({required this.community, required this.onTap, required this.onJoin});

  Widget _topBanner(Color color) {
    if (community.imagePath != null && !kIsWeb) {
      return SizedBox(
        height: 90, width: double.infinity,
        child: Image.file(File(community.imagePath!), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _emojiBanner(color)),
      );
    }
    return _emojiBanner(color);
  }

  Widget _emojiBanner(Color color) => Container(
    height: 90,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, (color.r * 0.5).round(), (color.g * 0.4).round(), (color.b * 0.5).round()),
          color.withValues(alpha: 0.85),
        ],
      ),
    ),
    child: Stack(
      children: [
        Positioned(right: -10, top: -10,
          child: Opacity(opacity: 0.15,
            child: Text(community.emoji, style: const TextStyle(fontSize: 90)))),
        Center(child: Text(community.emoji, style: const TextStyle(fontSize: 38))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBanner(color),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Text(community.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(_fmt(community.memberCount),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.neutral400),
                      const SizedBox(width: 3),
                      Text('${_fmt(community.pinCount)}핀',
                          style: const TextStyle(fontSize: 11, color: AppColors.neutral400)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: const Text('참여',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
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
}

// ── 코드로 참여 바텀시트 ─────────────────────────────────────────────────────────
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
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('코드로 커뮤니티 참여',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('초대 코드 6자리를 입력하세요',
                        style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.ctrl,
              autofocus: true,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                color: AppColors.primary,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: TextStyle(
                  fontSize: 22, letterSpacing: 8,
                  color: AppColors.neutral500.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
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
                  disabledBackgroundColor: AppColors.neutral200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('참여하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
