import 'package:flutter/material.dart';
import '../../../core/theme/tigo_colors.dart';
import '../../../core/services/pin_service.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';
import '../services/tigo_service.dart';
import '../widgets/tigo_avatar.dart';

const _kSlotLabels = {
  TigoSlot.hat: '모자',
  TigoSlot.outfit: '옷',
  TigoSlot.bag: '가방',
  TigoSlot.camera: '카메라',
  TigoSlot.badge: '뱃지',
  TigoSlot.skin: '스킨',
};

class TigoClosetScreen extends StatefulWidget {
  const TigoClosetScreen({super.key});

  @override
  State<TigoClosetScreen> createState() => _TigoClosetScreenState();
}

class _TigoClosetScreenState extends State<TigoClosetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  TravelStats? _stats;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: TigoSlot.values.length, vsync: this);
    TigoService.instance.addListener(_onServiceChange);
    _loadStats();
  }

  @override
  void dispose() {
    TigoService.instance.removeListener(_onServiceChange);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

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
            _TigoHeader(state: state, stats: _stats),
            _SlotTabBar(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
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
          _ProgressBar(
            count: state.uploadCount,
            nextThreshold: _nextThreshold(state),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  int _nextThreshold(TigoState state) {
    for (final item in kTigoItems) {
      if (!state.unlockedItemIds.contains(item.id)) return item.threshold;
    }
    return -1;
  }
}

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

class _ProgressBar extends StatelessWidget {
  final int count;
  final int nextThreshold;
  const _ProgressBar({required this.count, required this.nextThreshold});

  @override
  Widget build(BuildContext context) {
    if (nextThreshold == -1) {
      return _pill('모든 아이템 획득 완료! 🎉');
    }

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

  int _prevThreshold(int count) {
    final thresholds = kTigoItems.map((i) => i.threshold).toList()..sort();
    int prev = 0;
    for (final t in thresholds) {
      if (t > count) break;
      prev = t;
    }
    return prev;
  }

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
class _SlotGrid extends StatelessWidget {
  final TigoSlot slot;
  final TigoState state;
  const _SlotGrid({required this.slot, required this.state});

  @override
  Widget build(BuildContext context) {
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
        return _ItemCard(
          item: item,
          unlocked: unlocked,
          isEquipped: isEquipped,
          uploadCount: state.uploadCount,
          onTap: unlocked
              ? () => TigoService.instance.toggleEquip(item.id)
              : null,
        );
      },
    );
  }
}

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
                  if (!unlocked) ...[
                    const SizedBox(height: 4),
                    Text(
                      '사진 ${item.threshold - uploadCount}장 더!',
                      style: TextStyle(fontSize: 11, color: TigoColors.orange),
                    ),
                  ],
                ],
              ),
            ),
            if (!unlocked)
              Positioned(
                top: 8, right: 8,
                child: Icon(Icons.lock_rounded, size: 18, color: TigoColors.locked),
              ),
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
