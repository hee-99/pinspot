import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/core/models/pin_model.dart';

// SharedPreferences 기반 핀(PinModel) CRUD 서비스
class PinService {
  static const _key = 'saved_pins';

  // 저장된 모든 핀을 불러오고, 좌표 범위가 잘못된 항목은 걸러냄
  static Future<List<PinModel>> getPins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) {
          try {
            final pin = PinModel.fromJson(json.decode(e) as Map<String, dynamic>);
            if (pin.lat < -90 || pin.lat > 90 || pin.lng < -180 || pin.lng > 180) return null;
            return pin;
          } catch (_) {
            return null;
          }
        })
        .whereType<PinModel>()
        .toList();
  }

  // 새 핀을 JSON으로 직렬화해 저장 목록에 추가
  static Future<void> savePin(PinModel pin) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(json.encode(pin.toJson()));
    await prefs.setStringList(_key, list);
  }

  // id가 일치하는 핀을 저장 목록에서 제거
  static Future<void> deletePin(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((e) {
      try {
        final m = json.decode(e) as Map<String, dynamic>;
        return m['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, list);
  }
}

// 핀 추가/변경 시 다른 화면(지도 등)에 갱신을 알리는 글로벌 notifier
class PinRefreshNotifier extends ChangeNotifier {
  static final instance = PinRefreshNotifier._();
  PinRefreshNotifier._();
  void notifyPinAdded() => notifyListeners();
}
