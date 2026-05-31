import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ko'));

  static const _key = 'app_locale';
  static const _supported = ['ko', 'en', 'ja', 'zh'];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && _supported.contains(saved)) {
      localeNotifier.value = Locale(saved);
      return;
    }
    // Auto-detect from device
    final deviceCode = WidgetsBinding
        .instance.platformDispatcher.locale.languageCode;
    localeNotifier.value =
        Locale(_supported.contains(deviceCode) ? deviceCode : 'en');
  }

  static Future<void> setLocale(String languageCode) async {
    if (!_supported.contains(languageCode)) return;
    localeNotifier.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }

  static String get currentCode => localeNotifier.value.languageCode;
}
