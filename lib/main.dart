import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

// ★ 카카오 개발자 콘솔(https://developers.kakao.com)에서 발급받은
//   네이티브 앱 키로 교체하세요.
//   AndroidManifest.xml 과 iOS/Info.plist 의 YOUR_KAKAO_APP_KEY 도 동일하게 교체합니다.
const String _kakaoAppKey = 'YOUR_KAKAO_APP_KEY';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: _kakaoAppKey);
  runApp(const PinspotApp());
}

class PinspotApp extends StatelessWidget {
  const PinspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PINSPOT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
