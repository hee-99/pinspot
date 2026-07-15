import '../models/tigo_model.dart';

const List<TigoItem> kTigoItems = [
  TigoItem(
    id: 'camera_vintage',
    slot: TigoSlot.camera,
    name: '기본 카메라',
    asset: 'assets/tigo/items/camera_vintage.png',
    emoji: '📷',
    unlock: UploadCountUnlock(0),
    zIndex: 2,
  ),
  TigoItem(
    id: 'hat_explorer',
    slot: TigoSlot.hat,
    name: '탐험가 모자',
    asset: 'assets/tigo/items/hat_explorer.png',
    emoji: '🎩',
    unlock: UploadCountUnlock(5),
    zIndex: 4,
  ),
  TigoItem(
    id: 'outfit_tshirt',
    slot: TigoSlot.outfit,
    name: '여행 티셔츠',
    asset: 'assets/tigo/items/outfit_tshirt.png',
    emoji: '👕',
    unlock: UploadCountUnlock(15),
    zIndex: 1,
  ),
  TigoItem(
    id: 'bag_hiking',
    slot: TigoSlot.bag,
    name: '하이킹 백팩',
    asset: 'assets/tigo/items/bag_hiking.png',
    emoji: '🎒',
    unlock: UploadCountUnlock(30),
    zIndex: 3,
  ),
  TigoItem(
    id: 'badge_travel',
    slot: TigoSlot.badge,
    name: '여행 뱃지 패치',
    asset: 'assets/tigo/items/badge_travel.png',
    emoji: '🏅',
    unlock: UploadCountUnlock(50),
    zIndex: 5,
  ),
  TigoItem(
    id: 'skin_special',
    slot: TigoSlot.skin,
    name: '스페셜 스킨',
    asset: 'assets/tigo/items/skin_special.png',
    emoji: '✨',
    unlock: UploadCountUnlock(100),
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
