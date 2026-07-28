enum TigoSlot { hat, outfit, bag, camera, badge, skin }

abstract class TigoUnlock {
  const TigoUnlock();
}

class UploadCountUnlock extends TigoUnlock {
  final int threshold;
  const UploadCountUnlock(this.threshold);
}

class RegionUnlock extends TigoUnlock {
  final String category;
  const RegionUnlock(this.category);
}

/// 인앱결제로 구매해서 해금하는 프리미엄 아이템.
/// [productId]는 Play Console(수익 창출 > 제품 > 인앱 상품)에 등록한 상품 ID와 반드시 동일해야 함.
class PurchaseUnlock extends TigoUnlock {
  final int priceKrw;
  final String productId;
  const PurchaseUnlock(this.priceKrw, this.productId);
}

class TigoItem {
  final String id;
  final TigoSlot slot;
  final String name;
  final String asset;
  final String emoji;
  final TigoUnlock unlock;
  final int zIndex;

  const TigoItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.asset,
    required this.emoji,
    required this.unlock,
    required this.zIndex,
  });

  bool isUnlocked(int uploadCount) {
    if (unlock is UploadCountUnlock) {
      return uploadCount >= (unlock as UploadCountUnlock).threshold;
    }
    // Region unlock: handled separately (always locked in Phase 1)
    return false;
  }

  int get threshold {
    if (unlock is UploadCountUnlock) return (unlock as UploadCountUnlock).threshold;
    return 999;
  }

  bool get isPremium => unlock is PurchaseUnlock;

  int? get priceKrw => unlock is PurchaseUnlock ? (unlock as PurchaseUnlock).priceKrw : null;

  String? get productId => unlock is PurchaseUnlock ? (unlock as PurchaseUnlock).productId : null;
}

class TigoState {
  final int uploadCount;
  final List<String> unlockedItemIds;
  final Map<TigoSlot, String> equipped;

  const TigoState({
    required this.uploadCount,
    required this.unlockedItemIds,
    required this.equipped,
  });

  TigoState copyWith({
    int? uploadCount,
    List<String>? unlockedItemIds,
    Map<TigoSlot, String>? equipped,
  }) => TigoState(
    uploadCount: uploadCount ?? this.uploadCount,
    unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
    equipped: equipped ?? this.equipped,
  );
}

class TravelStats {
  final int visitedCities;
  final int footprints;
  final int photos;

  const TravelStats({
    required this.visitedCities,
    required this.footprints,
    required this.photos,
  });
}
