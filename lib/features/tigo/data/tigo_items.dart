import '../models/tigo_model.dart';

const List<TigoItem> kTigoItems = [
  TigoItem(
    id: 'camera_vintage',
    slot: TigoSlot.camera,
    name: '기본 카메라',
    emoji: '📷',
    unlock: UploadCountUnlock(0),
    zIndex: 2,
  ),
  TigoItem(
    id: 'hat_explorer',
    slot: TigoSlot.hat,
    name: '탐험가 모자',
    emoji: '🎩',
    unlock: UploadCountUnlock(5),
    zIndex: 4,
  ),
  TigoItem(
    id: 'outfit_tshirt',
    slot: TigoSlot.outfit,
    name: '여행 티셔츠',
    emoji: '👕',
    unlock: UploadCountUnlock(15),
    zIndex: 1,
  ),
  TigoItem(
    id: 'bag_hiking',
    slot: TigoSlot.bag,
    name: '하이킹 백팩',
    emoji: '🎒',
    unlock: UploadCountUnlock(30),
    zIndex: 3,
  ),
  TigoItem(
    id: 'badge_travel',
    slot: TigoSlot.badge,
    name: '여행 뱃지 패치',
    emoji: '🏅',
    unlock: UploadCountUnlock(50),
    zIndex: 5,
  ),
  TigoItem(
    id: 'skin_special',
    slot: TigoSlot.skin,
    name: '스페셜 스킨',
    emoji: '✨',
    unlock: UploadCountUnlock(100),
    zIndex: 0,
  ),
  TigoItem(
    id: 'skin_golden_tiger',
    slot: TigoSlot.skin,
    name: '황금 호랑이 스킨',
    emoji: '🐯',
    unlock: PurchaseUnlock(2900, 'tigo_skin_golden_tiger'),
    zIndex: 0,
  ),
];

TigoItem? tigoItemById(String id) {
  try {
    return kTigoItems.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
}

TigoItem? tigoItemByProductId(String productId) {
  try {
    return kTigoItems.firstWhere((item) => item.productId == productId);
  } catch (_) {
    return null;
  }
}

/// Play Console(수익 창출 > 제품 > 인앱 상품)에 그대로 등록해야 하는 상품 ID 목록.
List<String> get kTigoPremiumProductIds =>
    kTigoItems.where((i) => i.isPremium).map((i) => i.productId!).toList();
