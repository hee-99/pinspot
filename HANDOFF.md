# Pinspot — HANDOFF.md

> 마지막 업데이트: 2026-06-05

---

## 현재 완성 상태

### 완료된 기능

| 기능 | 파일 | 상태 |
|------|------|------|
| 스플래시 (다크 포레스트 + 글로우 펄스) | `auth/screens/splash_screen.dart` | ✅ |
| 온보딩 (최초 1회) | `auth/screens/onboarding_screen.dart` | ✅ |
| 로그인 (카카오/네이버/구글/애플/이메일) | `auth/screens/login_screen.dart` | ✅ |
| 바텀 네비 4탭 리디자인 | `home/screens/home_screen.dart` | ✅ |
| 지도 화면 (GPS + 마커 + 경로) | `map/screens/map_screen.dart` | ✅ |
| 핀 등록 (사진/EXIF GPS) | `pin/screens/create_pin_screen.dart` | ✅ |
| 커뮤니티 통합 3탭 (발견/그룹/팔로잉) | `community/screens/community_screen.dart` | ✅ |
| 커뮤니티 상세 + 생성 | `community/screens/community_detail_screen.dart` | ✅ |
| 핀플러 프로필/랭킹/지도 | `community/screens/pinpler_*.dart` | ✅ |
| 프로필 화면 | `profile/screens/profile_screen.dart` | ✅ |
| 다국어 4개 언어 | `core/l10n/app_localizations.dart` | ✅ |
| AI 랜드마크 정보 (Claude API) | `core/services/landmark_info_service.dart` | ✅ |
| Forest Green 디자인 시스템 | `core/theme/app_colors.dart` | ✅ |
| 개인정보 동의 시트 | `home/screens/home_screen.dart` | ✅ |

### 데이터 구조 (로컬 only)

- `PinModel`: id, title, lat, lng, category, photoPath, description, createdAt
- `CommunityModel`: id, name, emoji, color, isJoined, isPrivate, joinCode, pinCount, memberCount
- `UserModel`: id, name, email, provider

---

## 다음 할 일 (우선순위 순)

### P0 — 핵심 기능 연동

1. **실제 Google Maps API 연동 완성**
   - 현재: 지도는 뜨지만 핀 클러스터링 없음
   - 할 일: 핀 개수 많아질 때 클러스터링 (`google_maps_cluster_manager` 패키지)

2. **핀 등록 → 지도 즉시 반영**
   - 현재: `PinRefreshNotifier` 구현됨, 지도 탭 갱신 확인 필요
   - 할 일: CreatePinScreen에서 pop 후 MapScreen 마커 업데이트 테스트

3. **커뮤니티 발견/팔로잉 탭 실제 데이터 연결**
   - 현재: `_discoverMaps`, `_activityItems`, `_allPosts` 전부 하드코딩 목업
   - 할 일: CommunityService / PinService 실제 데이터로 교체

### P1 — UX 개선

4. **지도 화면 — 내 현위치 GPS 버튼**
   - 현재: 앱 시작 시 1회 GPS 요청, 이후 내 위치로 돌아가는 버튼 없음
   - 할 일: FAB 또는 앱바 아이콘으로 `_moveTo(currentPos)` 추가

5. **핀 등록 흐름 개선**
   - 현재: GPS 없이도 핀 등록 가능 (lat/lng 0,0으로 저장됨)
   - 할 일: 위치 미획득 시 지도에서 직접 찍기 옵션 추가

6. **프로필 — 팔로워/팔로잉 기능**
   - 현재: 더미 숫자 표시
   - 할 일: UserModel에 팔로우 관계 추가 + PinplrProfileScreen 연동

### P2 — 출시 준비

7. **API 키 보안**
   - 현재: Google Maps API Key, Kakao Key 코드에 하드코딩
   - 할 일: `--dart-define` 또는 `.env` 패턴으로 분리, Google Cloud 도메인 제한 설정

8. **서버/백엔드 연동 (현재 전부 로컬)**
   - SharedPreferences → Firebase Firestore 또는 Supabase 마이그레이션
   - 이미지 업로드: Firebase Storage 또는 S3
   - 소셜 팔로우 관계: 서버 필수

9. **feed_screen.dart 정리**
   - 현재: 파일 존재하지만 네비에서 제거됨 (커뮤니티에 통합)
   - 할 일: 파일 삭제 또는 내부 로직 community_screen.dart로 완전 이전

---

## 막힌 부분 / 주의사항

### 알려진 버그

| 이슈 | 위치 | 상태 |
|------|------|------|
| 소셜 로그인 버튼 Material assertion (수정 완료) | `login_screen.dart` | ✅ 해결 |
| Web에서 `Image.file()` 크래시 | 전체 | `kIsWeb` 체크로 회피 중 |
| 카카오 로그인: 실기기 필요 (에뮬레이터 미지원) | `auth_service.dart` | 알려진 제약 |

### 주의사항

- **`PinRefreshNotifier`**: `community_screen.dart`에 정의됨. 다른 화면에서 핀 변경 시 반드시 `PinRefreshNotifier.instance.notifyListeners()` 호출
- **다국어**: 새 문자열 추가 시 `_strings` Map의 ko/en/ja/zh 4개 섹션 모두 작성 필수
- **커뮤니티 joinCode**: 6자리 대문자 alphanumeric, `CommunityService.joinByCode()`로 참여
- **Google Maps style**: `assets/map_style.json` — 삭제하면 기본 Google 스타일로 폴백

---

## 이어서 할 작업 제안

바로 시작하기 좋은 것:

```
1. MapScreen — 현위치 복귀 버튼 추가 (30분)
2. 커뮤니티 발견탭 — _discoverMaps 목업을 PinService 실제 데이터로 교체 (1시간)
3. feed_screen.dart 파일 삭제 정리 (10분)
```
