import 'package:flutter/material.dart';
import 'package:pinspot/design/theme/app_colors.dart';

// 폰트: 시스템 기본 (Pretendard 추가 시 fontFamily: 'Pretendard' 로 교체)
// letterSpacing 음수값 → 한글에서 더 자연스럽고 모던하게 읽힘
// 앱 전역 텍스트 스타일 토큰 모음 (Display/Headline/Body/Label/Caption 계층)
abstract class AppTextStyles {
  // ─── Display ─────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.neutral900, letterSpacing: -0.8, height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.neutral900, letterSpacing: -0.6, height: 1.25,
  );

  // ─── Headline ─────────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.neutral900, letterSpacing: -0.4, height: 1.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 19, fontWeight: FontWeight.w600,
    color: AppColors.neutral900, letterSpacing: -0.3, height: 1.35,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.neutral900, letterSpacing: -0.2, height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.neutral900, letterSpacing: -0.1, height: 1.6,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.neutral600, letterSpacing: -0.1, height: 1.55,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.neutral500, letterSpacing: 0, height: 1.5,
  );

  // ─── Label ────────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.neutral900, letterSpacing: -0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.neutral600, letterSpacing: 0,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.neutral400, letterSpacing: 0.2,
  );

  // ─── Caption / Overline ───────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.neutral400, letterSpacing: 0,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.neutral400, letterSpacing: 0.8,
  );
}
