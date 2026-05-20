import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/community_model.dart';
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
                  if (!widget.community.isOwner)
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

class _PinFeedTab extends StatelessWidget {
  final CommunityModel community;
  const _PinFeedTab({required this.community});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: community.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(community.emoji,
                    style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('아직 핀이 없어요',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('핀 등록 후 이 커뮤니티에 공유하면\n여기서 모아볼 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  final CommunityModel community;
  const _MapTab({required this.community});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 60, color: community.color.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('커뮤니티 지도',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('멤버들이 공유한 핀이\n지도에 표시될 예정이에요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6)),
          ],
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return '$count';
}
