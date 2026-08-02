import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 팔로우한 사람의 핀 등록 알림 on/off 설정을 저장/복원하고 전역으로 알리는 서비스
// (서버가 없는 로컬 앱이라 실제 알림 발송 로직은 없음 — 나중에 백엔드 연동 시 이 토글에 연결)
class NotificationSettingsService {
  // 팔로우 핀 알림 on/off 상태를 앱 전체에 반영하기 위한 전역 알림자 (기본값: 켜짐)
  static final ValueNotifier<bool> followPinAlertNotifier =
      ValueNotifier(true);

  static const _key = 'notif_follow_pin_alert';

  // 저장된 알림 설정을 불러오거나, 없으면 기본값(켜짐)으로 시작
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    followPinAlertNotifier.value = prefs.getBool(_key) ?? true;
  }

  // 알림 설정을 변경하고 SharedPreferences에 저장
  static Future<void> setFollowPinAlert(bool enabled) async {
    followPinAlertNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }

  static bool get followPinAlertEnabled => followPinAlertNotifier.value;
}
