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

class TigoItem {
  final String id;
  final TigoSlot slot;
  final String name;
  final String asset;
  final TigoUnlock unlock;
  final int zIndex;

  const TigoItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.asset,
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
