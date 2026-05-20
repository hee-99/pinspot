import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await CommunityService.getCommunities();
    if (mounted) setState(() { _communities = list; _loading = false; });
  }

  List<CommunityModel> get _joined => _communities.where((c) => c.isJoined).toList();
  List<CommunityModel> get _explore => _communities.where((c) => !c.isJoined).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            tooltip: '만들기',
            onPressed: _openCreate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: CustomScrollView(
                slivers: [
                  // 내 커뮤니티
                  if (_joined.isNotEmpty) ...[
                    _SectionHeader(title: '내 커뮤니티', count: _joined.length),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 148,
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

                  // 둘러보기
                  _SectionHeader(
                    title: _joined.isEmpty ? '커뮤니티 둘러보기' : '둘러보기',
                    count: _explore.length,
                  ),
                  if (_explore.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('모든 커뮤니티에 참여 중이에요 🎉',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                            child: _CommunityCard(
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
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppTheme.primary,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('커뮤니티 만들기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// 내 커뮤니티 가로 스크롤 카드
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
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(community.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: color),
                        const SizedBox(width: 2),
                        Text(_fmt(community.pinCount),
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
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

// ─────────────────────────────────────
// 둘러보기 리스트 카드
class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  const _CommunityCard({
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final color = community.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // 왼쪽 이모지 영역
            Container(
              width: 80, height: 88,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Center(
                child: Text(community.emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(width: 14),
            // 중간 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(community.description,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(_fmt(community.memberCount),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text('${_fmt(community.pinCount)}핀',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 참여 버튼
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: onJoin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text('참여',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
