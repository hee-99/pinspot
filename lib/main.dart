import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
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
