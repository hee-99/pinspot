import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pin_model.dart';

class PinService {
  static const _key = 'saved_pins';

  static Future<List<PinModel>> getPins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) {
          try {
            return PinModel.fromJson(json.decode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PinModel>()
        .toList();
  }

  static Future<void> savePin(PinModel pin) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(json.encode(pin.toJson()));
    await prefs.setStringList(_key, list);
  }

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

class PinRefreshNotifier extends ChangeNotifier {
  static final instance = PinRefreshNotifier._();
  PinRefreshNotifier._();
  void notifyPinAdded() => notifyListeners();
}
