import 'package:flutter/material.dart';
import 'package:pinspot/design/theme/tigo_colors.dart';
import 'package:pinspot/features/pin/services/pin_service.dart';
import 'package:pinspot/features/tigo/data/tigo_items.dart';
import 'package:pinspot/features/tigo/models/tigo_model.dart';
import 'package:pinspot/features/tigo/services/tigo_service.dart';
import 'package:pinspot/features/tigo/services/tigo_purchase_service.dart';
import 'package:pinspot/features/tigo/widgets/tigo_avatar.dart';

// 슬롯별 탭에 표시할 한글 라벨
const _kSlotLabels = {
  TigoSlot.hat: '모자',
  TigoSlot.outfit: '옷',
  TigoSlot.bag: '가방',
  TigoSlot.camera: '카메라',
  TigoSlot.badge: '뱃지',
  TigoSlot.skin: '스킨',
};

// 티고 도감/꾸미기 화면 진입점 — 슬롯별 탭으로 아이템을 보여줌
class TigoClosetScreen extends StatefulWidget {
  const TigoClosetScreen({super.key});

  @override
  State<TigoClosetScreen> createState() => _TigoClosetScreenState();
}

// 도감 화면의 상태 관리 — 탭 컨트롤러, 티고 서비스 변경 구독, 여행 통계 로드
class _TigoClosetScreenState extends State<TigoClosetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  TravelStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: TigoSlot.values.length, vsync: this);
    // 아이템 해금/장착 상태가 바뀌면 화면을 다시 그리도록 구독
    TigoService.instance.addListener(_onServiceChange);
    _loadStats();
  }

  @override
  void dispose() {
    TigoService.instance.removeListener(_onServiceChange);
    _tabCtrl.dispose();
    super.dispose();
  }

  // 티고 서비스 상태 변경 시 화면 갱신
  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  // 저장된 핀 목록으로부터 여행 통계(도시/발자국/사진 수)를 계산해 로드
  Future<void> _loadStats() async {
    final pins = await PinService.getPins();
    if (mounted) {
      setState(() => _stats = TigoService.computeStats(pins));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = TigoService.instance.state;
    return Scaffold(
      backgroundColor: TigoColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더: 티고 아바타 + 통계 + 다음 해금까지 진행도
            _TigoHeader(state: state, stats: _stats),
            // 슬롯(모자/옷/가방 등) 선택 탭바
            _SlotTabBar(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                // 슬롯별 아이템 그리드를 탭 개수만큼 생성
                children: TigoSlot.values.map((slot) {
                  return _SlotGrid(slot: slot, state: state);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
// 화면 상단 헤더 — 제목, 업로드 뱃지, 티고 아바타, 통계, 다음 아이템 진행바
class _TigoHeader extends StatelessWidget {
  final TigoState state;
  final TravelStats? stats;
  const _TigoHeader({required this.state, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: TigoColors.cream,
      child: Column(
        children: [
          // 제목 + 누적 업로드 장수 뱃지
          Row(
            children: [
              Text(
                '티고 도감',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: TigoColors.brown,
                ),
              ),
              const Spacer(),
              _UploadBadge(count: state.uploadCount),
            ],
          ),
          const SizedBox(height: 16),
          // 현재 장착 아이템이 반영된 티고 아바타 + 인사말/통계
          Row(
            children: [
              TigoAvatar(size: 120, equipped: state.equipped),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '안녕! 나는 티고야',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: TigoColors.brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '사진을 많이 찍을수록\n더 많이 꾸밀 수 있어!',
                      style: TextStyle(
                        fontSize: 13,
                        color: TigoColors.brown.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (stats != null) _StatsRow(stats: stats!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 다음 무료 해금 아이템까지 남은 진행도 표시
          _ProgressBar(
            count: state.uploadCount,
            nextThreshold: _nextThreshold(state),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // 프리미엄이 아닌 아이템 중 아직 해금되지 않은 가장 낮은 임계값을 찾음 (없으면 -1)
  int _nextThreshold(TigoState state) {
    for (final item in kTigoItems) {
      if (item.isPremium) continue;
      if (!state.unlockedItemIds.contains(item.id)) return item.threshold;
    }
    return -1;
  }
}

// 누적 업로드 사진 장수를 보여주는 뱃지
class _UploadBadge extends StatelessWidget {
  final int count;
  const _UploadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TigoColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count장',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// 방문 도시/발자국/사진 수를 나열하는 통계 행
class _StatsRow extends StatelessWidget {
  final TravelStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: '도시', value: '${stats.visitedCities}'),
        const SizedBox(width: 8),
        _StatChip(label: '발자국', value: '${stats.footprints}'),
        const SizedBox(width: 8),
        _StatChip(label: '사진', value: '${stats.photos}'),
      ],
    );
  }
}

// 통계 항목 하나(값 + 라벨)를 표시하는 작은 칩
class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TigoColors.orange)),
        Text(label, style: TextStyle(fontSize: 10, color: TigoColors.brown.withValues(alpha: 0.6))),
      ],
    );
  }
}

// 다음 무료 아이템 해금까지의 진행률 바 (모두 획득 시 완료 알약 표시)
class _ProgressBar extends StatelessWidget {
  final int count;
  final int nextThreshold;
  const _ProgressBar({required this.count, required this.nextThreshold});

  @override
  Widget build(BuildContext context) {
    // 다음 임계값이 없으면(-1) 모든 무료 아이템을 이미 획득한 것
    if (nextThreshold == -1) {
      return _pill('모든 아이템 획득 완료! 🎉');
    }

    // 이전 임계값 대비 현재 업로드 수의 비율로 진행률 계산
    final prevThreshold = _prevThreshold(count);
    final range = nextThreshold - prevThreshold;
    final progress = ((count - prevThreshold) / range).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('다음 아이템까지', style: TextStyle(fontSize: 12, color: TigoColors.brown.withValues(alpha: 0.6))),
            Text('${nextThreshold - count}장 더!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TigoColors.orange)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: TigoColors.orangeSoft.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(TigoColors.orange),
          ),
        ),
      ],
    );
  }

  // 현재 업로드 수보다 작거나 같은 임계값 중 가장 큰 값을 찾음(진행바 시작점)
  int _prevThreshold(int count) {
    final thresholds = kTigoItems.where((i) => !i.isPremium).map((i) => i.threshold).toList()..sort();
    int prev = 0;
    for (final t in thresholds) {
      if (t > count) break;
      prev = t;
    }
    return prev;
  }

  // 완료 상태를 알약 모양 배지로 그려주는 헬퍼
  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TigoColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: TigoColors.orange, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────
// 슬롯(모자/옷/가방 등) 종류를 선택하는 스크롤 가능한 탭바
class _SlotTabBar extends StatelessWidget {
  final TabController controller;
  const _SlotTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TigoColors.cream,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: TigoColors.orange,
        unselectedLabelColor: TigoColors.brown.withValues(alpha: 0.45),
        indicatorColor: TigoColors.orange,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: TigoSlot.values
            .map((s) => Tab(text: _kSlotLabels[s]!))
            .toList(),
      ),
    );
  }
}

// ── Slot Grid ─────────────────────────────────────────────────────────────────
// 선택된 슬롯에 속한 아이템들을 그리드로 보여주는 위젯
class _SlotGrid extends StatelessWidget {
  final TigoSlot slot;
  final TigoState state;
  const _SlotGrid({required this.slot, required this.state});

  @override
  Widget build(BuildContext context) {
    // 현재 슬롯에 속한 아이템만 필터링 후 임계값(획득 조건) 오름차순 정렬
    final items = kTigoItems.where((i) => i.slot == slot).toList()
      ..sort((a, b) => a.threshold.compareTo(b.threshold));

    if (items.isEmpty) {
      return Center(
        child: Text('준비 중', style: TextStyle(color: TigoColors.brown.withValues(alpha: 0.4))),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final unlocked = state.unlockedItemIds.contains(item.id);
        final isEquipped = state.equipped[item.slot] == item.id;
        // 해금된 아이템은 탭 시 장착/해제 토글, 잠긴 프리미엄 아이템은 구매 다이얼로그,
        // 잠긴 무료 아이템은 탭 불가(onTap == null)로 처리
        VoidCallback? onTap;
        if (unlocked) {
          onTap = () => TigoService.instance.toggleEquip(item.id);
        } else if (item.isPremium) {
          onTap = () => _showPurchaseDialog(context, item);
        }
        return _ItemCard(
          item: item,
          unlocked: unlocked,
          isEquipped: isEquipped,
          uploadCount: state.uploadCount,
          onTap: onTap,
        );
      },
    );
  }

  // 프리미엄 아이템 구매 확인 다이얼로그 — 실제 스토어 상품 여부에 따라 안내 문구를 다르게 보여줌
  void _showPurchaseDialog(BuildContext context, TigoItem item) {
    // 스토어에 등록된 실제 상품이 있으면 해당 가격을, 없으면 앱에 정의된 기본 가격을 사용
    final product = TigoPurchaseService.instance.productFor(item);
    final priceLabel = product?.price ?? '₩${item.priceKrw}';
    final isRealStore = product != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${item.emoji} ${item.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          isRealStore
              ? '프리미엄 아이템이에요. $priceLabel에 구매하면 도감에서 바로 꾸밀 수 있어요.\n결제는 Google Play 결제창에서 진행돼요.'
              : '프리미엄 아이템이에요. $priceLabel에 구매하면 도감에서 바로 꾸밀 수 있어요.\n'
                '(아직 스토어 상품이 등록/조회되지 않아 지금은 개발용 테스트로 확인만 하면 바로 해금돼요.)',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TigoColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            // 구매 버튼 클릭 시 실제 인앱결제를 시도하고, 실패하면 개발용 폴백으로 해금
            onPressed: () async {
              Navigator.pop(ctx);
              final started = await TigoPurchaseService.instance.buy(item);
              if (!started) {
                // 스토어 상품 미등록/미조회 상태의 개발용 폴백.
                await TigoService.instance.purchaseItem(item.id);
              }
              // 실제 스토어 결제 성공 시의 해금은 purchaseStream 콜백에서 비동기로 처리됨.
            },
            child: Text('$priceLabel 구매하기'),
          ),
        ],
      ),
    );
  }
}

// 아이템 하나를 나타내는 카드 — 해금/장착/잠금/구매 상태에 따라 다르게 표시
class _ItemCard extends StatelessWidget {
  final TigoItem item;
  final bool unlocked;
  final bool isEquipped;
  final int uploadCount;
  final VoidCallback? onTap;

  const _ItemCard({
    required this.item,
    required this.unlocked,
    required this.isEquipped,
    required this.uploadCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isEquipped
              ? TigoColors.orange.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEquipped ? TigoColors.orange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: unlocked ? 1.0 : 0.3,
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: unlocked ? TigoColors.brown : TigoColors.locked,
                    ),
                  ),
                  // 잠긴 아이템은 프리미엄이면 가격을, 무료면 남은 필요 장수를 안내
                  if (!unlocked) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.isPremium
                          ? '₩${item.priceKrw} 구매'
                          : '사진 ${item.threshold - uploadCount}장 더!',
                      style: TextStyle(fontSize: 11, color: TigoColors.orange, fontWeight: item.isPremium ? FontWeight.w800 : FontWeight.w400),
                    ),
                  ],
                ],
              ),
            ),
            // 잠긴 아이템은 우측 상단에 구매(쇼핑백)/잠금 아이콘 표시
            if (!unlocked)
              Positioned(
                top: 8, right: 8,
                child: Icon(
                  item.isPremium ? Icons.shopping_bag_rounded : Icons.lock_rounded,
                  size: 18,
                  color: item.isPremium ? TigoColors.orange : TigoColors.locked,
                ),
              ),
            // 현재 장착 중인 아이템은 우측 상단에 체크 표시
            if (isEquipped)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: TigoColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
