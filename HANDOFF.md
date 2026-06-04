# Pinspot — HANDOFF.md

> 마지막 업데이트: 2026-06-05

---

## 오늘 완료한 작업 (2026-06-05)

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
| 지도 화면 (GPS + 마커 + 경로) | `map/screens/map_screen.dart` | ✅ |
| 핀 등록 (사진/EXIF GPS) | `pin/screens/create_pin_screen.dart` | ✅ |
| 커뮤니티 통합 3탭 (그룹/발견/팔로잉) | `community/screens/community_screen.dart` | ✅ |
| 커뮤니티 상세 + 생성 | `community/screens/community_detail_screen.dart` | ✅ |
| 핀플러 프로필/랭킹/지도 | `community/screens/pinpler_*.dart` | ✅ |
| 프로필 화면 | `profile/screens/profile_screen.dart` | ✅ |
| 다국어 4개 언어 (ko/en/ja/zh) | `core/l10n/app_localizations.dart` | ✅ |
| AI 랜드마크 정보 (Claude API) | `core/services/landmark_info_service.dart` | ✅ |
| Forest Green 디자인 시스템 | `core/theme/app_colors.dart` | ✅ |

---

## 다음 할 일 (우선순위 순)

### P0 — 핵심 UX

1. **지도 화면 — 현위치 복귀 버튼**
   - 현재: 앱 시작 시 1회 GPS, 이후 내 위치로 돌아가는 버튼 없음
   - 할 일: 우하단 FAB 또는 앱바 아이콘으로 `_moveTo(currentPos)` 추가

2. **커뮤니티 발견 탭 — 실제 데이터 연결**
   - 현재: `_discoverMaps`, `_activityItems`, `_allPosts` 전부 하드코딩 목업
   - 할 일: PinService 실제 데이터로 교체

3. **핀 등록 → 지도 즉시 반영 테스트**
   - `PinRefreshNotifier` 구현됨, CreatePinScreen pop 후 MapScreen 마커 갱신 확인 필요

### P1 — 정리

4. **`feed_screen.dart` 삭제**
   - 네비에서 완전 제거됨, 파일만 남아있음
   - 안전하게 삭제 후 커밋

5. **핀 등록 — 위치 미획득 시 처리**
   - 현재: GPS 없으면 lat/lng 0,0으로 저장
   - 할 일: 지도에서 직접 위치 선택 옵션 추가

### P2 — 출시 준비

6. **API 키 보안 분리** — `--dart-define` 또는 `.env`
7. **서버/백엔드 연동** — 현재 전부 SharedPreferences 로컬 저장

---

## 알려진 이슈 / 주의사항

| 이슈 | 위치 | 상태 |
|------|------|------|
| 소셜 로그인 버튼 Material assertion | `login_screen.dart` | ✅ 수정됨 |
| Web에서 `Image.file()` 크래시 | 전체 | `kIsWeb` 체크로 회피 중 |
| 카카오 로그인 에뮬레이터 미지원 | `auth_service.dart` | 실기기 필요 |
| `feed_screen.dart` 미사용 파일 잔존 | `features/feed/` | 다음 세션에 삭제 예정 |

---

## 코드 주의사항

- `PinRefreshNotifier`: `community_screen.dart`에 정의됨. 핀 변경 후 반드시 `PinRefreshNotifier.instance.notifyListeners()` 호출
- 새 문자열 추가 시 `_strings` Map의 ko/en/ja/zh 4개 섹션 모두 작성 필수
- 기본 탭: 지도 (index 1, _currentIndex = 1)
