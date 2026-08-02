// 티고 아바타에 장착 가능한 아이템 슬롯 종류
enum TigoSlot { hat, outfit, bag, camera, badge, skin }

// 티고 아이템 해금 조건을 나타내는 추상 클래스
abstract class TigoUnlock {
  const TigoUnlock();
}

// 업로드(핀 등록) 개수 기준으로 해금되는 조건
class UploadCountUnlock extends TigoUnlock {
  final int threshold;
  const UploadCountUnlock(this.threshold);
}

// 특정 지역/카테고리 방문 기준으로 해금되는 조건 (Phase 1에서는 항상 잠김 처리)
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

// 티고 꾸미기에 사용되는 개별 아이템 정보 (모자, 옷, 가방 등)
class TigoItem {
  final String id;
  final TigoSlot slot;
  final String name;
  final String emoji;
  final TigoUnlock unlock;
  final int zIndex;

  const TigoItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.emoji,
    required this.unlock,
    required this.zIndex,
  });

  // 현재 업로드 개수 기준으로 이 아이템이 해금됐는지 판단
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

  // 인앱결제로 구매해야 하는 프리미엄 아이템인지 여부
  bool get isPremium => unlock is PurchaseUnlock;

  int? get priceKrw => unlock is PurchaseUnlock ? (unlock as PurchaseUnlock).priceKrw : null;

  String? get productId => unlock is PurchaseUnlock ? (unlock as PurchaseUnlock).productId : null;
}

// 사용자별 티고 상태 — 업로드 수, 해금된 아이템 목록, 슬롯별 장착 아이템
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

// 프로필 화면 등에 노출되는 여행 통계 (방문 도시, 발자취, 사진 수)
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
