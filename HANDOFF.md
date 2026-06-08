# Pinspot — HANDOFF.md

> 마지막 업데이트: 2026-06-08

---

## 오늘 완료한 작업 (2026-06-08)

| 작업 | 커밋 |
|------|------|
| 앱 아이콘 임시 변경 — 다크 포레스트 + 라임 그린 핀 (카카오맵 차별화) | `952e8a7` |
| feed_screen.dart 삭제 — 커뮤니티 탭 통합 완료, 미사용 파일 제거 | `952e8a7` |

---

## 이전 완료한 작업 (2026-06-05)

| 작업 | 커밋 |
|------|------|
| 피드 탭 제거 → 커뮤니티 3탭 통합 (발견/그룹/팔로잉) | `c49588c` |
| CLAUDE.md (프로젝트 규칙·폴더 구조) 작성 | `c49588c` |
| 바텀 네비 탭 순서: 핀 맨 왼쪽으로 이동 (핀→지도→커뮤니티→프로필) | `b8d1289` |
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
| 바텀 네비 4탭 (핀→지도→커뮤니티→프로필) | `home/screens/home_screen.dart` | ✅ |
| 지도 화면 (GPS + 마커 + 경로 + 현위치 버튼) | `map/screens/map_screen.dart` | ✅ |
| 핀 등록 (사진/EXIF GPS) + 지도 즉시 반영 | `pin/screens/create_pin_screen.dart` | ✅ |
| 커뮤니티 통합 3탭 (그룹/발견/팔로잉) | `community/screens/community_screen.dart` | ✅ |
| 커뮤니티 상세 + 생성 | `community/screens/community_detail_screen.dart` | ✅ |
| 핀플러 프로필/랭킹/지도 | `community/screens/pinpler_*.dart` | ✅ |
| 프로필 화면 | `profile/screens/profile_screen.dart` | ✅ |
| 다국어 4개 언어 (ko/en/ja/zh) | `core/l10n/app_localizations.dart` | ✅ |
| AI 랜드마크 정보 (Claude API) | `core/services/landmark_info_service.dart` | ✅ |
| Forest Green 디자인 시스템 | `core/theme/app_colors.dart` | ✅ |

---

## 막힌 부분 (Blockers)

| 항목 | 내용 |
|------|------|
| 🎨 **앱 아이콘 미확정** | 다크핀/캐릭터/지도/카메라/네온 등 다양한 시안 탐색했으나 방향 미결정. 디자이너 or 직접 결정 필요. 현재 android에는 임시 다크핀 버전 적용 중 |
| 📱 **에뮬레이터 불안정** | Pixel 8 에뮬레이터 부팅 후 앱 연결이 간헐적으로 끊김. 실기기 테스트 필요 |
| 🔑 **카카오 로그인** | 에뮬레이터 미지원. 실기기에서만 테스트 가능 |

---

## 다음 할 일 (우선순위 순)

### P0 — 당장 해야 할 것

1. **앱 패키지명 변경** ← 출시 전 필수
   - 현재: `com.example.pinspot` (Flutter 기본값)
   - 변경 필요: `com.pinspot.app` 또는 원하는 패키지명
   - 파일: `android/app/build.gradle`, `AndroidManifest.xml`, `main.dart`

2. **앱 이름 변경**
   - 현재: pubspec.yaml `name: pinspot`, 앱 표시명 미설정
   - 변경: `android/app/src/main/AndroidManifest.xml` → `android:label="핀스팟"` (또는 "Pinspot")

3. **앱 아이콘 확정 및 적용**
   - 시안 검토 후 결정 → 디자인 확정되면 모든 해상도 교체

### P1 — 기능 개선

4. **핀 GPS 없을 때 위치 선택**
   - 현재: GPS 미획득 시 lat/lng 0,0으로 저장됨
   - 할 일: 지도에서 직접 탭해서 위치 지정하는 옵션 추가
   - 파일: `pin/screens/create_pin_screen.dart`

5. **커뮤니티 발견 탭 — 인기 지도 섹션**
   - 현재: `_discoverMaps`, `_allPosts` 하드코딩 목업
   - "내 지도 컬렉션"은 실제 PinService 연동됨 ✅
   - 인기 지도는 서버 없이는 의미 있는 데이터 불가 → 백엔드 연동 시 처리

### P2 — 출시 준비

6. **API 키 보안 분리** — Google Maps, Kakao 키를 `--dart-define` 또는 `.env`로
7. **서버/백엔드 연동** — 현재 전부 SharedPreferences 로컬 저장, 실제 DB 연동 필요
8. **앱스토어 등록 준비** — 스크린샷, 설명, 개인정보처리방침

---

## 알려진 이슈 / 주의사항

| 이슈 | 위치 | 상태 |
|------|------|------|
| 소셜 로그인 버튼 Material assertion | `login_screen.dart` | ✅ 수정됨 |
| Web에서 `Image.file()` 크래시 | 전체 | `kIsWeb` 체크로 회피 중 |
| 카카오 로그인 에뮬레이터 미지원 | `auth_service.dart` | 실기기 필요 |
| feed_screen.dart 미사용 파일 잔존 | `features/feed/` | ✅ 삭제 완료 |
| 앱 패키지명 com.example.pinspot | 전체 | ⚠️ 출시 전 필수 변경 |

---

## 코드 주의사항

- `PinRefreshNotifier`: `community_screen.dart`에 정의됨. 핀 변경 후 반드시 `PinRefreshNotifier.instance.notifyListeners()` 호출
- 새 문자열 추가 시 `_strings` Map의 ko/en/ja/zh 4개 섹션 모두 작성 필수
- 기본 탭: 지도 (index 1, `_currentIndex = 1`)
- Google Maps API Key: `android/app/src/main/AndroidManifest.xml` (출시 전 도메인 제한 설정 필요)
