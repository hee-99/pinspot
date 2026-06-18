import 'package:flutter/material.dart';

abstract class AppColors {
  // ─── Primary · TIGO Orange ────────────────────────────────────────────────
  static const Color primary      = Color(0xFFFF8A00); // TIGO Orange 메인 브랜드
  static const Color primaryLight = Color(0xFFFFF3E0); // Orange-50  칩·선택 배경
  static const Color primaryMuted = Color(0xFFFFD494); // Orange-200 배지·태그
  static const Color primaryDark  = Color(0xFFB35E00); // Orange-900 눌림·딥 포인트

  // ─── TIGO 브랜드 팔레트 ────────────────────────────────────────────────────
  static const Color tigoBrown  = Color(0xFF4A2C17); // 텍스트·다크
  static const Color tigoCream  = Color(0xFFF5E9D6); // 배경·면
  static const Color tigoGreen  = Color(0xFF6E8B57); // 자연·포인트
  static const Color tigoOrangeSoft = Color(0xFFFFC98B); // 서브·하이라이트

  // ─── Neutrals · Warm-toned ────────────────────────────────────────────────
  static const Color neutral50  = Color(0xFFFAF8F4); // 앱 기본 배경 (따뜻한 화이트)
  static const Color neutral100 = Color(0xFFF5F0E8); // 섹션 배경·입력 필드
  static const Color neutral200 = Color(0xFFE8DFD0); // 구분선·얇은 테두리
  static const Color neutral300 = Color(0xFFCFC3B0); // 굵은 테두리
  static const Color neutral400 = Color(0xFF9E8E78); // 힌트·비활성 텍스트
  static const Color neutral500 = Color(0xFF7A6A55); // 보조 텍스트
  static const Color neutral600 = Color(0xFF4A3C2C); // 본문 텍스트
  static const Color neutral900 = Color(0xFF1C1009); // 제목·강조 텍스트

  // ─── Surfaces ─────────────────────────────────────────────────────────────
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceOverlay = Color(0xF5FFFFFF);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF6E8B57); // TIGO green
  static const Color error   = Color(0xFFDC2626);
  static const Color warning = Color(0xFFFF8A00);
  static const Color info    = Color(0xFF0284C7);

  // ─── Map ──────────────────────────────────────────────────────────────────
  static const Color mapPin       = Color(0xFFFF8A00); // TIGO orange 마커
  static const Color mapPinShadow = Color(0x33FF8A00);
  static const Color mapRoute     = Color(0xFF0284C7);

  // ─── Dark hero (splash / login) ────────────────────────────────────────────
  static const Color darkBg    = Color(0xFF1C0C02); // 딥 브라운 블랙
  static const Color darkBgMid = Color(0xFF3A1C08); // 미드 브라운
}
