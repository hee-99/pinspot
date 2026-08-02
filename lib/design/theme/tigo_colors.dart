import 'package:flutter/material.dart';

// 티고(마스코트) 관련 UI에서 쓰는 색상 토큰 모음
abstract class TigoColors {
  static const Color orange      = Color(0xFFFF8A00); // 메인 브랜드
  static const Color orangeSoft  = Color(0xFFFFC98B); // 서브·하이라이트
  static const Color brown       = Color(0xFF4A2C17); // 텍스트·다크
  static const Color cream       = Color(0xFFF5E9D6); // 배경·면
  static const Color green       = Color(0xFF6E8B57); // 자연·포인트

  static const Color orangeLight = Color(0xFFFFF3E0); // 카드 배경
  static const Color brownDark   = Color(0xFF2D1A0E); // 딥 브라운
  static const Color locked      = Color(0xFFB0B0B0); // 잠긴 아이템 색
}
