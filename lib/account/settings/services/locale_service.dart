import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 언어 설정을 저장/복원하고 전역으로 알리는 서비스
class LocaleService {
  // 현재 언어를 앱 전체에 반영하기 위한 전역 알림자
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ko'));

  static const _key = 'app_locale';
  static const _supported = ['ko', 'en', 'ja', 'zh'];

  // 저장된 언어 설정을 불러오거나, 없으면 기기 언어를 감지해 초기화
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

  // 언어를 변경하고 SharedPreferences에 저장
  static Future<void> setLocale(String languageCode) async {
    if (!_supported.contains(languageCode)) return;
    localeNotifier.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }

  static String get currentCode => localeNotifier.value.languageCode;
}
