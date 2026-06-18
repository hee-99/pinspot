import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tigo_colors.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/services/pin_service.dart';
import '../../tigo/screens/tigo_closet_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  List<PinModel> _recentPins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
    PinRefreshNotifier.instance.addListener(_loadPins);
  }

  @override
  void dispose() {
    PinRefreshNotifier.instance.removeListener(_loadPins);
    super.dispose();
  }

  Future<void> _loadPins() async {
    final pins = await PinService.getPins();
    pins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() { _recentPins = pins.take(10).toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TigoColors.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildGreeting()),
            SliverToBoxAdapter(child: _buildHeroCard()),
            SliverToBoxAdapter(child: _buildSectionHeader(context)),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: TigoColors.orange)),
                ),
              )
            else if (_recentPins.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PinListItem(pin: _recentPins[i]),
                  childCount: _recentPins.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── 상단 인사 영역 ─────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, 여행자!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: TigoColors.brown,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '오늘은 어디로 떠나볼까요?',
                  style: TextStyle(
                    fontSize: 14,
                    color: TigoColors.brown.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          // 알림 벨 아이콘
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.notifications_none_rounded, color: TigoColors.brown, size: 22),
          ),
        ],
      ),
    );
  }

  // ── 히어로 카드 ───────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TigoClosetScreen())),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/tigo/tigo_hero.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: TigoColors.orangeLight,
                    child: Center(child: Icon(Icons.pets, size: 60, color: TigoColors.orange)),
                  ),
                ),
                // 하단 그라데이션 + 텍스트
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          TigoColors.brown.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('티고와 함께 여행 기록',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                            Text('발톱 자국을 남겨요 🐾',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: TigoColors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('티고 꾸미기',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 섹션 헤더 ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Text('최근 여행 기록',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: TigoColors.brown)),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Text('더보기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TigoColors.orange)),
          ),
        ],
      ),
    );
  }

  // ── 빈 상태 ────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(Icons.photo_camera_outlined, size: 48, color: TigoColors.orange.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('아직 여행 기록이 없어요',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: TigoColors.brown.withValues(alpha: 0.6))),
            const SizedBox(height: 6),
            Text('📷 카메라 버튼으로 첫 발톱 자국을 남겨보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TigoColors.brown.withValues(alpha: 0.4), height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── 핀 리스트 아이템 ───────────────────────────────────────────────────────────
class _PinListItem extends StatelessWidget {
  final PinModel pin;
  const _PinListItem({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // 사진 썸네일
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: SizedBox(
              width: 80, height: 80,
              child: _buildThumbnail(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pin.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: TigoColors.brown)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TigoColors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(pin.category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TigoColors.orange)),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(pin.createdAt),
                          style: TextStyle(fontSize: 11, color: AppColors.neutral400)),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(pin.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: TigoColors.brown.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.neutral300, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (pin.photoPath != null && !kIsWeb) {
      return Image.file(File(pin.photoPath!), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: TigoColors.orangeLight,
      child: Center(child: Icon(Icons.photo_outlined, color: TigoColors.orange, size: 28)),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
