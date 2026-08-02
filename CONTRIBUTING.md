# Pinspot 협업 가이드

이 문서는 `hee-99`, `pinverse-de` 두 명이 이 저장소에서 겹치지 않고 나눠서 작업할 수 있도록 정리한 안내입니다. 프로젝트 전반의 규칙/구조는 `CLAUDE.md`에 더 자세히 있으니 함께 참고하세요.

## 1. 폴더 구조 — 누가 어디를 건드리는지

`lib/` 밑은 역할별로 4개 영역으로 나뉘어 있습니다.

```
lib/
├── main.dart          # 앱 진입점
├── core/              # 여러 영역이 공통으로 쓰는 것 (데이터 모델, 다국어, 공용 서비스)
├── design/            # 디자인 — 색상/폰트/테마, 공용 위젯, 지도 마커 아이콘 등 시각적인 것만
├── features/          # 앱 기능 — 지도, 핀 등록, 커뮤니티, 티고(아바타/꾸미기) 등 핵심 기능 로직
└── account/           # 계정 관리 — 로그인/회원가입, 프로필, 언어 등 설정 화면
```

| 폴더 | 담당 영역 | 예시 |
|---|---|---|
| `lib/design/` | 색상 팔레트, 폰트, 테마, 공용 위젯, 마커 아이콘 등 **눈에 보이는 스타일**만 수정할 때 | `theme/app_colors.dart`, `widgets/translatable_text.dart` |
| `lib/features/` | 지도, 핀 등록, 커뮤니티, 티고 꾸미기 등 **앱의 핵심 기능 로직** | `map/screens/map_screen.dart`, `pin/screens/create_pin_screen.dart` |
| `lib/account/` | 로그인/회원가입, 내 프로필, 언어 설정 등 **내 계정을 관리하는 화면** | `auth/screens/login_screen.dart`, `profile/screens/profile_screen.dart` |
| `lib/core/` | 위 세 영역이 공통으로 참조하는 데이터 모델·다국어 문자열·다기능 공용 서비스 (여기 수정 시 영향 범위가 넓으니 상대방과 미리 상의) | `models/pin_model.dart`, `l10n/app_localizations.dart` |

같은 폴더 안의 파일을 동시에 수정하면 충돌 가능성이 높으니, 되도록 서로 다른 영역(design/features/account)을 나눠 맡는 걸 권장합니다.

내부 import는 전부 `package:pinspot/...` 절대경로를 씁니다 (상대경로 `../../`는 쓰지 않음). 파일을 옮기거나 새로 만들 때도 이 방식을 유지해주세요.

## 2. 개발 환경 설치 및 실행

1. Flutter 3.32.0 / Dart SDK ^3.8.0 설치
2. `flutter pub get`
3. API 키 설정 (레포에 커밋되지 않는 파일들이라 각자 직접 채워야 함)
   - `dart_defines/keys.env.example`을 복사해 `dart_defines/keys.env` 생성 후 `KAKAO_APP_KEY`, `GEMINI_API_KEY`, `GOOGLE_DIRECTIONS_API_KEY` 값을 채움
   - `android/local.properties`에 Google Maps SDK 키, Naver 키 설정 (기존 팀원에게 값 공유받기)
4. 실행/빌드는 반드시 `--dart-define-from-file` 옵션을 붙여야 함:
   ```bash
   flutter run --dart-define-from-file=dart_defines/keys.env
   flutter build apk --release --dart-define-from-file=dart_defines/keys.env
   ```
   이 옵션 없이 실행하면 카카오 로그인 등 키가 필요한 기능이 동작하지 않습니다.

## 3. Git 협업 규칙 (제안)

- `master`는 항상 실행 가능한 상태로 유지. 직접 push하지 않고 브랜치 + PR로 병합합니다.
- 브랜치 이름 예시: `feature/맡은-작업-이름` (예: `feature/tigo-shop-ui`, `account/login-bugfix`)
- 작업 전 최신 `master`를 받고 브랜치 생성:
  ```bash
  git checkout master && git pull
  git checkout -b feature/작업이름
  ```
- 커밋은 작업 단위로 자주, 커밋 메시지는 무엇을/왜 바꿨는지 한 줄 요약
- 작업이 끝나면 GitHub에서 Pull Request 생성 → 서로 리뷰 후 `master`로 병합
- 같은 파일을 동시에 여러 명이 수정할 것 같으면 미리 이야기해서 충돌을 줄이기 (특히 `lib/core/`, `pubspec.yaml`)
- `flutter analyze`가 깨끗한 상태(에러 0건)로 PR을 올리기

## 4. 참고

- 전체 프로젝트 규칙/화면 흐름/디자인 시스템은 `CLAUDE.md` 참고
- 코드 전반에 한글 주석이 달려 있으니, 처음 보는 파일은 클래스/메서드 위 주석부터 훑어보면 구조 파악이 빠릅니다.
