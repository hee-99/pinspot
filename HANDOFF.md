# Pinspot — HANDOFF.md

> 마지막 업데이트: 2026-06-17

---

## 오늘 완료한 작업 (2026-06-17)

| 작업 | 상태 |
|------|------|
| 샘플 핀 26개 시딩 (서울 전역 — 등산/계곡/캠핑/맛집/관광/사진명소/폐허) | ✅ |
| 앱 아이콘 교체 — PINSPOT_icon_green (Emerald #17B96A, 귀여운 핀 캐릭터) | ✅ |
| Android adaptive icon — mipmap-*/ic_launcher_foreground.png + @color/ic_launcher_background #17B96A | ✅ |
| iOS AppIcon.appiconset — 모든 사이즈 PNG 교체 (20~1024px) | ✅ |
| Android 12 시스템 스플래시 — 다크 배경 (#091408) + 새 아이콘 | ✅ |
| Flutter 스플래시 — 핀 캐릭터 바운스+스쿼시 애니메이션 + 로딩바 | ✅ |

---

## 이전 완료한 작업 (2026-06-08)

| 작업 | 커밋 |
|------|------|
| feed_screen.dart 삭제 | `952e8a7` |
| 앱 패키지명 `com.pinspot.pinspot` → `com.pinspot.app` | `4047118` |
| 앱 표시명 `"pinspot"` → `"Pinspot"` | `4047118` |
| 핀 등록 위치 검증 실패 UX 개선 (GPS/EXIF/거리 케이스별 안내) | `2d8a142` |
| API 키 보안 분리 (dart-define + local.properties) | `edf9410` |

---

## 이전 완료한 작업 (2026-06-05)

| 작업 | 커밋 |
|------|------|
| 피드 탭 제거 → 커뮤니티 3탭 통합 (발견/그룹/팔로잉) | `c49588c` |
| CLAUDE.md (프로젝트 규칙·폴더 구조) 작성 | `c49588c` |
| 바텀 네비 탭 순서: 핀 맨 왼쪽으로 이동 | `b8d1289` |
| 커뮤니티 내부 탭 순서: 그룹→발견→팔로잉 | `f81f286` |

---

## 현재 완성 상태

### 화면 구조

```
바텀 네비 4탭:
[ 📍 핀 ] [ 🗺 지도 ] [ 👥 커뮤니티 ] [ 👤 프로필 ]
  (모달)   (기본탭)

커뮤니티 내부 3탭:
[ 👥 그룹 ] [ ✨ 발견 ] [ 🔔 팔로잉 ]
```

### 완료된 기능

| 기능 | 파일 | 상태 |
|------|------|------|
| 스플래시 (다크 포레스트 + 글로우 펄스) | `auth/screens/splash_screen.dart` | ✅ |
| 온보딩 (최초 1회) | `auth/screens/onboarding_screen.dart` | ✅ |
| 로그인 (카카오/네이버/구글/애플/이메일) | `auth/screens/login_screen.dart` | ✅ |
| 바텀 네비 4탭 | `home/screens/home_screen.dart` | ✅ |
| 지도 화면 (GPS + 마커 + 경로 + 현위치 버튼) | `map/screens/map_screen.dart` | ✅ |
| 핀 등록 (사진/EXIF GPS + 실패 UX 개선) | `pin/screens/create_pin_screen.dart` | ✅ |
| 커뮤니티 통합 3탭 | `community/screens/community_screen.dart` | ✅ |
| 커뮤니티 상세 + 생성 | `community/screens/community_detail_screen.dart` | ✅ |
| 핀플러 프로필/랭킹/지도 | `community/screens/pinpler_*.dart` | ✅ |
| 프로필 화면 | `profile/screens/profile_screen.dart` | ✅ |
| 다국어 4개 언어 (ko/en/ja/zh) | `core/l10n/app_localizations.dart` | ✅ |
| AI 랜드마크 정보 (Gemini API) | `core/services/landmark_info_service.dart` | ✅ |
| Forest Green 디자인 시스템 | `core/theme/app_colors.dart` | ✅ |
| API 키 보안 분리 | `dart_defines/`, `local.properties` | ✅ |

---

## 빌드 방법 (API 키 분리 후 변경됨)

```bash
# 개발 실행
flutter run --dart-define-from-file=dart_defines/keys.env

# Android release 빌드
flutter build apk --release --dart-define-from-file=dart_defines/keys.env
```

### API 키 설정 방법 (처음 셋업 시)

1. `dart_defines/keys.env.example` 복사 → `dart_defines/keys.env`
2. 실제 키 값 채우기
3. `android/local.properties`에 Android 키 추가:
   ```
   GOOGLE_MAPS_API_KEY=실제키
   NAVER_CLIENT_ID=실제키
   NAVER_CLIENT_SECRET=실제키
   ```

---

## 막힌 부분 (Blockers)

| 항목 | 내용 |
|------|------|
| 🎨 **앱 아이콘 미확정** | 다양한 시안 탐색했으나 방향 미결정. 현재 android에는 임시 다크핀 버전 적용 중 |
| 📱 **에뮬레이터 불안정** | Pixel 8 에뮬레이터 부팅 후 앱 연결이 간헐적으로 끊김. 실기기 테스트 권장 |
| 🔑 **카카오 로그인** | 에뮬레이터 미지원, 실기기에서만 테스트 가능 |

---

## 다음 할 일 (우선순위 순)

### P0 — 당장 해야 할 것

1. **앱 아이콘 확정 및 적용**
   - 시안 검토 후 결정 → 모든 해상도 교체

### P1 — 기능 개선

2. **커뮤니티 발견 탭 인기 지도 섹션**
   - 현재: 하드코딩 목업 데이터 (`_discoverMaps`, `_allPosts`)
   - "내 지도 컬렉션"은 실제 PinService 연동 완료
   - 서버 연동 전까지는 목업 유지 예정

### P2 — 출시 준비

3. **서버/백엔드 연동** — Firebase or Supabase 방향 결정 필요
   - 현재 전부 SharedPreferences 로컬 저장
   - 소셜 공유·커뮤니티 기능은 서버 없이는 한계

4. **앱스토어 등록 준비**
   - Google Play Console 등록
   - 스크린샷 (폰 프레임 포함 6장 이상)
   - 앱 설명문 (한국어/영어)
   - 개인정보처리방침 URL

5. **Google Maps API 키 도메인 제한**
   - 현재: 무제한 (출시 전 Android 패키지명으로 제한 필요)
   - Google Cloud Console → API 키 → Android 앱 제한

---

## 알려진 이슈 / 주의사항

| 이슈 | 위치 | 상태 |
|------|------|------|
| 소셜 로그인 버튼 Material assertion | `login_screen.dart` | ✅ 수정됨 |
| Web에서 `Image.file()` 크래시 | 전체 | `kIsWeb` 체크로 회피 중 |
| 카카오 로그인 에뮬레이터 미지원 | `auth_service.dart` | 실기기 필요 |
| 앱 패키지명 com.example.pinspot | — | ✅ com.pinspot.app으로 변경 완료 |
| API 키 코드 노출 | — | ✅ dart-define + local.properties로 분리 완료 |

---

## 코드 주의사항

- `PinRefreshNotifier`: `community_screen.dart`에 정의됨. 핀 변경 후 반드시 `PinRefreshNotifier.instance.notifyListeners()` 호출
- 새 문자열 추가 시 `_strings` Map의 ko/en/ja/zh 4개 섹션 모두 작성 필수
- 기본 탭: 지도 (index 1, `_currentIndex = 1`)
- Google Maps API Key: 출시 전 Google Cloud Console에서 Android 패키지명(`com.pinspot.app`)으로 제한 설정 필요
