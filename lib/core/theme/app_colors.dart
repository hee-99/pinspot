import 'package:flutter/material.dart';

abstract class AppColors {
  // ─── Primary · Forest Green ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF16A34A); // Green-600 메인 브랜드
  static const Color primaryLight = Color(0xFFF0FDF4); // Green-50  칩·선택 배경
  static const Color primaryMuted = Color(0xFFBBF7D0); // Green-200 배지·태그
  static const Color primaryDark  = Color(0xFF14532D); // Green-900 눌림·딥 포인트

  // ─── Neutrals · Cool-Green-tinted ────────────────────────────────────────
  static const Color neutral50  = Color(0xFFF7F8F4); // 앱 기본 배경
  static const Color neutral100 = Color(0xFFEEF0EB); // 섹션 배경·입력 필드
  static const Color neutral200 = Color(0xFFDEE1D9); // 구분선·얇은 테두리
  static const Color neutral300 = Color(0xFFC4C8BF); // 굵은 테두리
  static const Color neutral400 = Color(0xFF95998F); // 힌트·비활성 텍스트
  static const Color neutral500 = Color(0xFF6D7169); // 보조 텍스트
  static const Color neutral600 = Color(0xFF4C5048); // 본문 텍스트
  static const Color neutral900 = Color(0xFF11180F); // 제목·강조 텍스트

  // ─── Surfaces ────────────────────────────────────────────────────────────
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceOverlay = Color(0xF5FFFFFF);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info    = Color(0xFF0284C7);

  // ─── Map ─────────────────────────────────────────────────────────────────
  static const Color mapPin       = Color(0xFF16A34A);
  static const Color mapPinShadow = Color(0x3316A34A);
  static const Color mapRoute     = Color(0xFF0284C7);

  // ─── Dark hero (splash / login) ───────────────────────────────────────────
  static const Color darkBg    = Color(0xFF091408); // 딥 포레스트 블랙
  static const Color darkBgMid = Color(0xFF0F2212); // 미드톤 다크 그린
}
