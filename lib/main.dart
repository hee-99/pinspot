import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/landmark_info_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/sample_data_service.dart';
import 'features/auth/screens/splash_screen.dart';

const String _kakaoAppKey = String.fromEnvironment('KAKAO_APP_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: _kakaoAppKey);
  await LocaleService.init();
  await SampleDataService.seedIfEmpty();
  LandmarkInfoService.refreshStaleCacheInBackground().ignore();
  runApp(const PinspotApp());
}

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
