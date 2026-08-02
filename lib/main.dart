import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:pinspot/core/l10n/app_localizations.dart';
import 'package:pinspot/design/theme/app_theme.dart';
import 'package:pinspot/features/map/services/landmark_info_service.dart';
import 'package:pinspot/account/settings/services/locale_service.dart';
import 'package:pinspot/account/settings/services/notification_settings_service.dart';
import 'package:pinspot/account/auth/screens/splash_screen.dart';

// 빌드 시 --dart-define으로 주입되는 카카오 네이티브 앱 키
const String _kakaoAppKey = String.fromEnvironment('KAKAO_APP_KEY');

// 앱 진입점 — 카카오 SDK 초기화, 언어 설정 로드, 오래된 랜드마크 캐시 백그라운드 갱신 후 앱 실행
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: _kakaoAppKey);
  await LocaleService.init();
  await NotificationSettingsService.init();
  // 캐시 갱신은 앱 실행을 막지 않도록 결과를 기다리지 않고 백그라운드로 실행
  LandmarkInfoService.refreshStaleCacheInBackground().ignore();
  runApp(const PinspotApp());
}

// 앱 루트 위젯 — 테마/다국어/초기 화면(스플래시) 설정
class PinspotApp extends StatelessWidget {
  const PinspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'PINSPOT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
