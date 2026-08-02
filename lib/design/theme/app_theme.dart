import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/design/theme/app_text_styles.dart';

// Flutter ThemeData를 구성하는 앱 전역 테마 정의 클래스
class AppTheme {
  // ── 하위 호환 단축 접근자 ──────────────────────────────────────────────────
  static const Color primary       = AppColors.primary;
  static const Color background    = AppColors.neutral50;
  static const Color surface       = AppColors.surface;
  static const Color textPrimary   = AppColors.neutral900;
  static const Color textSecondary = AppColors.neutral500;

  // ── Light Theme ───────────────────────────────────────────────────────────
  // 앱 전체(MaterialApp)에 적용하는 라이트 테마 — 색상/버튼/입력창 등 위젯별 기본 스타일을 정의
  static ThemeData get light => ThemeData(
    useMaterial3: true,

    // ColorScheme
    colorScheme: const ColorScheme.light(
      primary:                AppColors.primary,
      onPrimary:              Colors.white,
      primaryContainer:       AppColors.primaryLight,
      onPrimaryContainer:     AppColors.primaryDark,
      secondary:              AppColors.neutral600,
      onSecondary:            Colors.white,
      surface:                AppColors.surface,
      onSurface:              AppColors.neutral900,
      surfaceContainerHighest: AppColors.neutral100,
      onSurfaceVariant:       AppColors.neutral500,
      outline:                AppColors.neutral200,
      outlineVariant:         AppColors.neutral300,
      error:                  AppColors.error,
      onError:                Colors.white,
    ),

    scaffoldBackgroundColor: AppColors.neutral50,

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor:   AppColors.surface,
      foregroundColor:   AppColors.neutral900,
      elevation:         0,
      scrolledUnderElevation: 0,
      centerTitle:       true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.dark,
        statusBarBrightness:      Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color:        AppColors.neutral900,
        fontSize:     17,
        fontWeight:   FontWeight.w600,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.neutral900, size: 24),
    ),

    // ── Bottom Navigation ───────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surface,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.neutral400,
      type:                 BottomNavigationBarType.fixed,
      elevation:            0,
      selectedLabelStyle:   TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
    ),

    // ── Card ────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color:     AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutral200, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── ElevatedButton ──────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2,
        ),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutral900,
        side: const BorderSide(color: AppColors.neutral300, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.2,
        ),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.1,
        ),
      ),
    ),

    // ── Input ───────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AppColors.neutral100,
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle:  const TextStyle(color: AppColors.neutral400, fontSize: 15),
      labelStyle: const TextStyle(color: AppColors.neutral500, fontSize: 15),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    ),

    // ── Chip ────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor:  AppColors.neutral100,
      selectedColor:    AppColors.primaryLight,
      disabledColor:    AppColors.neutral100,
      labelStyle: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral600,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
      ),
      side:  BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Divider ─────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color:     AppColors.neutral200,
      thickness: 1,
      space:     1,
    ),

    // ── BottomSheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation:     0,
      modalElevation: 0,
      dragHandleColor: AppColors.neutral300,
      dragHandleSize: Size(40, 4),
      showDragHandle: true,
    ),

    // ── FAB ─────────────────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation:       4,
      focusElevation:  6,
      shape:           const CircleBorder(),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      extendedTextStyle: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1,
      ),
    ),

    // ── Dialog ──────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation:       0,
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppTextStyles.headlineSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
    ),

    // ── SnackBar ────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutral900,
      contentTextStyle: const TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400,
      ),
      shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── TextTheme ───────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge:   AppTextStyles.displayLarge,
      displayMedium:  AppTextStyles.displayMedium,
      headlineLarge:  AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall:  AppTextStyles.headlineSmall,
      bodyLarge:      AppTextStyles.bodyLarge,
      bodyMedium:     AppTextStyles.bodyMedium,
      bodySmall:      AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.labelLarge,
      labelMedium:    AppTextStyles.labelMedium,
      labelSmall:     AppTextStyles.labelSmall,
    ),
  );
}
