# Pinspot — CLAUDE.md

## 프로젝트 개요

Flutter 위치 기반 소셜 핀 공유 앱.
슬로건: "찍는 순간, 기록이 된다"

- **플랫폼**: Android (primary), iOS, Web
- **Flutter**: 3.32.0 / Dart SDK ^3.8.0
- **GitHub**: https://github.com/hee-99/pinspot.git (브랜치: master)

---

## 폴더 구조

`lib/`는 협업자가 겹치지 않고 나눠서 작업할 수 있도록 **디자인 / 앱 기능 / 계정 관리** 3개 영역 + 공용 `core`로 재구조화되어 있음 (2026-08-02). 세부 작업 배분 규칙은 `CONTRIBUTING.md` 참고. 내부 import는 전부 `package:pinspot/...` 절대경로 사용 (상대경로 미사용).

```
lib/
├── main.dart                          # 앱 진입점, KakaoSdk init, LocaleService
├── core/                              # 3개 영역 공용 — 데이터 모델, 다국어, 다기능 공용 서비스
│   ├── l10n/
│   │   └── app_localizations.dart     # 4개 언어 문자열 (ko/en/ja/zh), 직접 관리 (ARB 미사용)
│   ├── models/
│   │   ├── pin_model.dart             # PinModel — id, title, lat, lng, category, photoPath, description
│   │   ├── community_model.dart       # CommunityModel — id, name, emoji, color, isJoined, isPrivate, joinCode
│   │   ├── landmark_info_model.dart   # LandmarkInfo — origin, highlights, bestTime, tip, sourceLabel
│   │   ├── pin_rating_schema.dart
│   │   ├── pinpler_tier.dart          # 핀플러 등급 체계
│   │   └── user_model.dart            # UserModel
│   └── services/
│       ├── category_service.dart      # 핀 카테고리 관리 (map + pin 공용)
│       └── translation_service.dart   # 번역 서비스 (여러 feature 공용)
│
├── design/                            # "디자인" — 순수 시각/테마 레이어, 비즈니스 로직 없음
│   ├── theme/
│   │   ├── app_colors.dart            # 색상 토큰 (TIGO 오렌지 팔레트)
│   │   ├── app_text_styles.dart
│   │   ├── app_theme.dart
│   │   └── tigo_colors.dart
│   ├── widgets/
│   │   └── translatable_text.dart     # 번역 가능한 텍스트 위젯
│   └── utils/
│       └── marker_builder.dart        # 지도 마커 커스텀 빌더
│
├── features/                          # "앱 기능" — 지도/핀/커뮤니티/티고 등 핵심 기능
│   ├── home/
│   │   └── screens/
│   │       ├── home_screen.dart       # 바텀 네비 4탭 + 개인정보 동의 시트
│   │       └── home_content_screen.dart
│   ├── map/
│   │   ├── screens/map_screen.dart    # Google Maps + GPS + 핀 마커 + 경로
│   │   └── services/ (directions_service.dart, landmark_info_service.dart)
│   ├── pin/
│   │   ├── screens/create_pin_screen.dart  # 핀 등록 (카메라/갤러리 + EXIF GPS)
│   │   └── services/pin_service.dart
│   ├── community/
│   │   ├── screens/
│   │   │   ├── community_screen.dart        # 3탭 통합 (발견/그룹/팔로잉) + 피드 흡수
│   │   │   ├── community_detail_screen.dart # 커뮤니티 상세
│   │   │   ├── create_community_screen.dart # 커뮤니티 생성
│   │   │   ├── pinpler_profile_screen.dart  # 핀플러 프로필
│   │   │   ├── pinpler_combined_map_screen.dart
│   │   │   └── pinpler_ranking_screen.dart
│   │   └── services/community_service.dart
│   └── tigo/                          # 티고 꾸미기(아바타/아이템 구매) 미니 모듈
│       ├── data/ (tigo_items.dart)
│       ├── models/ (tigo_model.dart)
│       ├── screens/ (tigo_closet_screen.dart)
│       ├── services/ (tigo_service.dart, tigo_purchase_service.dart)
│       └── widgets/ (tigo_avatar.dart, tigo_unlock_dialog.dart)
│
└── account/                           # "관리" — 계정/설정 관리
    ├── auth/
    │   ├── screens/
    │   │   ├── splash_screen.dart     # 스플래시 + 글로우 애니메이션
    │   │   ├── login_screen.dart      # 소셜 로그인 화면
    │   │   ├── onboarding_screen.dart # 최초 1회 온보딩
    │   │   └── email_auth_screen.dart # 이메일 로그인/회원가입
    │   └── services/
    │       ├── auth_service.dart      # 카카오/네이버/구글/애플/이메일 로그인
    │       └── sample_data_service.dart
    ├── profile/
    │   └── screens/profile_screen.dart # 프로필 + 내 핀 그리드 + 지도
    └── settings/
        ├── screens/language_test_screen.dart
        └── services/locale_service.dart  # 언어 설정 저장/복원

assets/
└── map_style.json                     # Google Maps 커스텀 스타일
```

---

## 화면 흐름

```
SplashScreen
  └─→ OnboardingScreen (최초 1회, SharedPreferences 플래그)
        └─→ LoginScreen
              └─→ HomeScreen (바텀 네비)
```

### 바텀 네비 — 4탭

```
[🗺 지도] [ 📍+핀 pill ] [👥 커뮤니티] [👤 프로필]
```

- **지도(0)**: MapScreen — Google Maps, GPS 현위치, 저장된 핀 마커, 카테고리 필터, 경로 안내
- **핀(1)**: CreatePinScreen 모달 — 카메라/갤러리, EXIF GPS 자동 추출
- **커뮤니티(2)**: CommunityScreen — 내부 3탭 (발견/그룹/팔로잉)
  - 발견: 인기 지도 컬렉션 히어로카드 + 그리드
  - 그룹: 커뮤니티 참여/탐색, 카테고리 필터, 코드 참여
  - 팔로잉: 활동 스트림 + 커뮤니티 공유 핀
- **프로필(3)**: ProfileScreen — 내 핀 그리드/지도, 언어 설정, 로그아웃

---

## 디자인 시스템

### 색상 팔레트 (Forest Green)

| 토큰 | 값 | 용도 |
|------|-----|------|
| `AppColors.primary` | `#16A34A` | 브랜드 주색 |
| `AppColors.primaryLight` | `#F0FDF4` | 칩·선택 배경 |
| `AppColors.primaryDark` | `#14532D` | 눌림·딥 포인트 |
| `AppColors.darkBg` | `#091408` | 스플래시/로그인 히어로 배경 |
| 크림 배경 (`_kBg`) | `#F5F3EE` | 커뮤니티/홈 배경 |
| 카드 (`_kCard`) | `#FFFFFF` | 카드 배경 |

### UI 규칙

- 카드 그림자: `BoxShadow(color: 0x0C000000, blurRadius: 16, offset: (0,4))`
- 카드 radius: 기본 20px, 작은 칩 16px
- 바텀 네비: 높이 60px, 상단 인디케이터 바 (active 시 18×3 green pill)
- 핀 버튼: 48×34 green pill, boxShadow 35% opacity
- 섹션 헤더: fontSize 16, fontWeight w800

---

## 다국어 (i18n)

- **지원**: 한국어(ko) · 영어(en) · 일본어(ja) · 중국어(zh)
- **구현**: `app_localizations.dart` 내 Map 직접 관리 (ARB/gen 미사용)
- **선택**: ProfileScreen → 언어 설정 → `LocaleService.setLocale()`
- **새 문자열 추가 시**: `_strings` Map의 4개 언어 섹션 모두 추가 필요

---

## 데이터 레이어

- **저장소**: SharedPreferences (로컬 only, 서버 없음)
- **핀**: `PinService` — CRUD, JSON 직렬화
- **커뮤니티**: `CommunityService` — CRUD, joinByCode, toggleJoin
- **AI 정보**: `LandmarkInfoService` — Claude API 호출, 캐시 (SharedPreferences)
- **인증**: `AuthService` — 카카오/네이버/구글/애플/이메일, 게스트 모드

---

## 코드 규칙

- private 위젯은 같은 파일 내 `_ClassName` 으로 정의 (별도 파일 분리 X)
- 색상은 `AppColors.*` 사용; 화면별 로컬 상수는 파일 상단 `const _k*` 패턴
- l10n 문자열 `AppLocalizations.of(context)` — `final l = AppLocalizations.of(context)` 줄여쓰기
- `PinRefreshNotifier.instance` — 핀 추가 후 다른 화면 갱신용 글로벌 notifier
- Google Maps: `_mapCtrl = Completer<GoogleMapController>()` 패턴 일관 사용
- 이미지: `kIsWeb` 체크 후 `Image.file()` (Web에서 File API 미지원)

---

## 빌드 / 실행

```bash
# 개발 실행
flutter run

# Android release
flutter build apk --release

# 연결 기기 확인
flutter devices
```

### 환경 키 (gitignore 대상 — 하드코딩 아님)

- `KAKAO_APP_KEY`, `GEMINI_API_KEY`, `GOOGLE_DIRECTIONS_API_KEY`: `dart_defines/keys.env` (템플릿: `keys.env.example`), 실행 시 `--dart-define-from-file=dart_defines/keys.env` 필요
- Google Maps SDK 키, Naver 키: `android/local.properties`
- 자세한 설치/실행 방법은 `CONTRIBUTING.md` 참고

---

## 알려진 제약

- 피드 탭은 네비에서 제거됨 — 커뮤니티 발견탭으로 통합. `feed_screen.dart` 파일 자체는 존재하지 않음(레거시 폴더도 정리됨).
- 발견/팔로잉 탭 데이터는 현재 하드코딩 목업 — 실제 서버 연동 전
