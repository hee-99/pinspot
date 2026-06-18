import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/pin_model.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';

class TigoService extends ChangeNotifier {
  static final instance = TigoService._();
  TigoService._();

  static const _kUploadCount = 'tigo_upload_count';
  static const _kUnlocked   = 'tigo_unlocked_ids';
  static const _kEquipped   = 'tigo_equipped';

  TigoState _state = const TigoState(
    uploadCount: 0,
    unlockedItemIds: [],
    equipped: {},
  );

  List<TigoItem> _pendingUnlock = [];

  TigoState get state => _state;

  /// Items newly unlocked since last call to [consumePendingUnlock].
  List<TigoItem> consumePendingUnlock() {
    final items = List<TigoItem>.from(_pendingUnlock);
    _pendingUnlock = [];
    return items;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kUploadCount) ?? 0;
    final unlocked = prefs.getStringList(_kUnlocked) ?? [];
    final equippedRaw = prefs.getString(_kEquipped);

    Map<TigoSlot, String> equipped = {};
    if (equippedRaw != null) {
      try {
        final m = json.decode(equippedRaw) as Map<String, dynamic>;
        m.forEach((k, v) {
          final slot = TigoSlot.values.firstWhere(
            (s) => s.name == k,
            orElse: () => TigoSlot.hat,
          );
          equipped[slot] = v as String;
        });
      } catch (_) {}
    }

    _state = TigoState(
      uploadCount: count,
      unlockedItemIds: unlocked,
      equipped: equipped,
    );

    // Sync any items that should be unlocked based on stored count
    _syncUnlocks(notify: false);
    notifyListeners();
  }

  Future<List<TigoItem>> incrementUploadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final newCount = _state.uploadCount + 1;
    await prefs.setInt(_kUploadCount, newCount);
    _state = _state.copyWith(uploadCount: newCount);

    final newItems = _syncUnlocks(notify: false);
    await _saveUnlocked(prefs);

    _pendingUnlock = newItems;
    notifyListeners();
    return newItems;
  }

  Future<void> toggleEquip(String itemId) async {
    final item = tigoItemById(itemId);
    if (item == null) return;
    if (!_state.unlockedItemIds.contains(itemId)) return;

    final equipped = Map<TigoSlot, String>.from(_state.equipped);
    if (equipped[item.slot] == itemId) {
      equipped.remove(item.slot);
    } else {
      equipped[item.slot] = itemId;
    }

    _state = _state.copyWith(equipped: equipped);
    await _saveEquipped();
    notifyListeners();
  }

  /// Returns newly unlocked items.
  List<TigoItem> _syncUnlocks({bool notify = true}) {
    final before = Set<String>.from(_state.unlockedItemIds);
    final unlocked = List<String>.from(_state.unlockedItemIds);

    for (final item in kTigoItems) {
      if (!unlocked.contains(item.id) && item.isUnlocked(_state.uploadCount)) {
        unlocked.add(item.id);
      }
    }

    _state = _state.copyWith(unlockedItemIds: unlocked);

    final newItems = kTigoItems
        .where((item) => unlocked.contains(item.id) && !before.contains(item.id))
        .toList();

    if (notify && newItems.isNotEmpty) notifyListeners();
    return newItems;
  }

  Future<void> _saveUnlocked(SharedPreferences prefs) async {
    await prefs.setStringList(_kUnlocked, _state.unlockedItemIds);
  }

  Future<void> _saveEquipped() async {
    final prefs = await SharedPreferences.getInstance();
    final m = _state.equipped.map((slot, id) => MapEntry(slot.name, id));
    await prefs.setString(_kEquipped, json.encode(m));
  }

  /// Computes travel stats from the given pin list.
  static TravelStats computeStats(List<PinModel> pins) {
    return TravelStats(
      visitedCities: _countCities(pins),
      footprints: pins.length,
      photos: pins.where((p) => p.photoPath != null).length,
    );
  }

  static int _countCities(List<PinModel> pins) {
    if (pins.isEmpty) return 0;
    const double radiusKm = 50.0;
    final used = <int>{};
    int count = 0;
    for (int i = 0; i < pins.length; i++) {
      if (used.contains(i)) continue;
      count++;
      for (int j = i + 1; j < pins.length; j++) {
        if (used.contains(j)) continue;
        if (_distKm(pins[i].lat, pins[i].lng, pins[j].lat, pins[j].lng) <= radiusKm) {
          used.add(j);
        }
      }
      used.add(i);
    }
    return count;
  }

  static double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final a = lat1 * (math.pi / 180);
    final b = lat2 * (math.pi / 180);
    final da = (lat2 - lat1) * (math.pi / 180);
    final dl = (lng2 - lng1) * (math.pi / 180);
    final x = math.sin(da / 2) * math.sin(da / 2) +
        math.cos(a) * math.cos(b) * math.sin(dl / 2) * math.sin(dl / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }
}
