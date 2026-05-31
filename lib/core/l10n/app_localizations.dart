import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;
  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? AppLocalizations('ko');
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('ko'), Locale('en'), Locale('ja'), Locale('zh'),
  ];

  String _t(String key) =>
      _strings[languageCode]?[key] ?? _strings['en']?[key] ?? key;

  String _tp(String key, Map<String, String> params) {
    var v = _t(key);
    params.forEach((k, val) => v = v.replaceAll('{$k}', val));
    return v;
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get navFeed => _t('nav_feed');
  String get navMap => _t('nav_map');
  String get navPin => _t('nav_pin');
  String get navCommunity => _t('nav_community');
  String get navProfile => _t('nav_profile');

  // ── Common ──────────────────────────────────────────────────────────────────
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get confirm => _t('confirm');
  String get or => _t('or');
  String get all => _t('all');
  String get share => _t('share');
  String get skip => _t('skip');
  String get next => _t('next');
  String get retry => _t('retry');
  String get done => _t('done');
  String get add => _t('add');
  String get logout => _t('logout');
  String get recommended => _t('recommended');
  String get loading => _t('loading');
  String get directions => _t('directions');

  // ── Login ───────────────────────────────────────────────────────────────────
  String get loginSubtitle => _t('login_subtitle');
  String get betaTest => _t('beta_test');
  String get tryNow => _t('try_now');
  String get tryNowDesc => _t('try_now_desc');
  String get startTest => _t('start_test');
  String get startWithSocial => _t('start_with_social');
  String get startWithKakao => _t('start_with_kakao');
  String get startWithNaver => _t('start_with_naver');
  String get startWithGoogle => _t('start_with_google');
  String get startWithApple => _t('start_with_apple');
  String get startWithEmail => _t('start_with_email');
  String get loginTerms => _t('login_terms');
  String providerSetupTitle(String provider) => _tp('provider_setup_title', {'provider': provider});
  String get providerSetupDesc => _t('provider_setup_desc');

  // ── Privacy ─────────────────────────────────────────────────────────────────
  String get privacyTitle => _t('privacy_title');
  String get privacyContent => _t('privacy_content');
  String get privacyAccept => _t('privacy_accept');

  // ── Profile ─────────────────────────────────────────────────────────────────
  String get editProfile => _t('edit_profile');
  String get nickname => _t('nickname');
  String get nicknameHint => _t('nickname_hint');
  String get notificationSettings => _t('notification_settings');
  String get privacySettings => _t('privacy_settings');
  String get languageSettings => _t('language_settings');
  String get logoutConfirm => _t('logout_confirm');
  String get pins => _t('pins');
  String get followers => _t('followers');
  String get following => _t('following');
  String get explorer => _t('explorer');
  String get noPins => _t('no_pins');
  String get noSavedPins => _t('no_saved_pins');
  String get addPinToMap => _t('add_pin_to_map');
  String get visitedPlaces => _t('visited_places');
  String get viewAll => _t('view_all');
  String myPinsCount(int n) => _tp('my_pins_count', {'n': '$n'});
  String categoryPlaces(String cat) => _tp('category_places', {'cat': cat});

  // ── Feed ────────────────────────────────────────────────────────────────────
  String get feedTabAll => _t('feed_tab_all');
  String get feedTabFollowing => _t('feed_tab_following');
  String get myPins => _t('my_pins');
  String get communityFeed => _t('community_feed');
  String get pinplerFeed => _t('pinpler_feed');
  String get noFollowing => _t('no_following');
  String get mapAppError => _t('map_app_error');
  String get aiInfo => _t('ai_info');
  String get aiLoading => _t('ai_loading');
  String get originHistory => _t('origin_history');
  String get highlights => _t('highlights');
  String get bestTime => _t('best_time');
  String get visitTip => _t('visit_tip');
  String get myPinLabel => _t('my_pin_label');
  String get pinpler => _t('pinpler');

  // ── Create Pin ──────────────────────────────────────────────────────────────
  List<String> get createSteps => [
    _t('create_step_0'), _t('create_step_1'), _t('create_step_2'),
    _t('create_step_3'), _t('create_step_4'),
  ];
  String get photoSourceQ => _t('photo_source_q');
  String get photoSourceDesc => _t('photo_source_desc');
  String get camera => _t('camera');
  String get cameraSubtitle => _t('camera_subtitle');
  String get gallery => _t('gallery');
  String get gallerySubtitle => _t('gallery_subtitle');
  String get location500mInfo => _t('location_500m_info');
  String get verifyingLocationMsg => _t('verifying_location_msg');
  String get locationSuccess => _t('location_success');
  String get locationFail => _t('location_fail');
  String get noGpsMsg => _t('no_gps_msg');
  String get noExifMsg => _t('no_exif_msg');
  String get cameraVerifyMsg => _t('camera_verify_msg');
  String get verifySuccessMsg => _t('verify_success_msg');
  String verifyFailMsg(String dist) => _tp('verify_fail_msg', {'dist': dist});
  String distanceToLocation(String n) => _tp('distance_to_location', {'n': n});
  String get category => _t('category');
  String get newCategory => _t('new_category');
  String get createCategory => _t('create_category');
  String get categoryNameHint => _t('category_name_hint');
  String get placeName => _t('place_name');
  String get placeNameHint => _t('place_name_hint');
  String get description => _t('description');
  String get descriptionHint => _t('description_hint');
  String get submitPin => _t('submit_pin');
  String get aiFetchLocation => _t('ai_fetch_location');
  String get aiFetching => _t('ai_fetching');
  String get aiEnterNameFirst => _t('ai_enter_name_first');
  String get useAiDescription => _t('use_ai_description');
  String get shareToCommunityQ => _t('share_to_community_q');
  String get shareSubtitle => _t('share_subtitle');
  String get noCommunity => _t('no_community');
  String get selectCommunity => _t('select_community');
  String shareNCommunities(int n) => _tp('share_n_communities', {'n': '$n'});
  String get pinRegistered => _t('pin_registered');
  String get pinRegisteredDesc => _t('pin_registered_desc');

  // ── Community ───────────────────────────────────────────────────────────────
  String get communityTitle => _t('community_title');
  String get myCommunities => _t('my_communities');
  String get exploreCommunities => _t('explore_communities');
  String get createCommunity => _t('create_community');
  String get joinCommunity => _t('join_community');
  String get joined => _t('joined');
  String get members => _t('members');
  String get searchCommunity => _t('search_community');
  String get noCommunityFound => _t('no_community_found');
  String get noJoinedCommunity => _t('no_joined_community');

  // ── Email Auth ──────────────────────────────────────────────────────────────
  String get emailLogin => _t('email_login');
  String get emailRegister => _t('email_register');
  String get email => _t('email');
  String get password => _t('password');
  String get passwordConfirm => _t('password_confirm');
  String get name => _t('name');
  String get emailHint => _t('email_hint');
  String get passwordHint => _t('password_hint');
  String get nameHint => _t('name_hint');
  String get emailRequired => _t('email_required');
  String get wrongCredentials => _t('wrong_credentials');
  String get passwordMismatch => _t('password_mismatch');
  String get passwordTooShort => _t('password_too_short');
  String get nameRequired => _t('name_required');

  // ── Time ────────────────────────────────────────────────────────────────────
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return _t('just_now');
    if (diff.inMinutes < 60) return _tp('minutes_ago', {'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return _tp('hours_ago', {'n': '${diff.inHours}'});
    if (diff.inDays < 7) return _tp('days_ago', {'n': '${diff.inDays}'});
    return '${dt.month}/${dt.day}';
  }

  // ── Language names ──────────────────────────────────────────────────────────
  static const languageNames = {
    'ko': '한국어',
    'en': 'English',
    'ja': '日本語',
    'zh': '中文',
  };

  static const languageFlags = {
    'ko': '🇰🇷',
    'en': '🇺🇸',
    'ja': '🇯🇵',
    'zh': '🇨🇳',
  };
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ko', 'en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── Translations ─────────────────────────────────────────────────────────────

const _strings = <String, Map<String, String>>{
  'ko': {
    // Navigation
    'nav_feed': '피드',
    'nav_map': '지도',
    'nav_pin': '핀등록',
    'nav_community': '커뮤니티',
    'nav_profile': '프로필',
    // Common
    'cancel': '취소',
    'save': '저장',
    'confirm': '확인',
    'or': '또는',
    'all': '전체',
    'share': '공유',
    'skip': '건너뛰기',
    'next': '다음 단계로',
    'retry': '다시 선택',
    'done': '완료',
    'add': '추가',
    'logout': '로그아웃',
    'recommended': '추천',
    'loading': '로딩 중...',
    'directions': '길찾기',
    // Login
    'login_subtitle': '찍는 순간, 지도가 된다',
    'beta_test': 'BETA TEST',
    'try_now': '바로 체험하기',
    'try_now_desc': '앱 키 설정 없이 모든 기능을 체험해보세요',
    'start_test': '테스트로 시작하기',
    'start_with_social': '소셜 계정으로 시작',
    'start_with_kakao': '카카오로 시작하기',
    'start_with_naver': '네이버로 시작하기',
    'start_with_google': 'Google로 시작하기',
    'start_with_apple': 'Apple로 시작하기',
    'start_with_email': '이메일로 시작하기',
    'login_terms': '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의합니다',
    'provider_setup_title': '{provider} 연동 준비 중',
    'provider_setup_desc': 'API 키 설정이 필요합니다.\n지금은 테스트 로그인을 이용해주세요.',
    // Privacy
    'privacy_title': '개인정보 처리 안내',
    'privacy_content':
        '핀스팟은 아래 정보를 수집합니다:\n\n'
        '• 위치 정보: 핀 등록 및 지도 표시에 사용\n'
        '• 사진: 핀 등록 시 첨부 (기기에만 저장)\n'
        '• 핀 데이터: 기기 내부 저장소에만 보관\n\n'
        '수집된 정보는 외부 서버로 전송되지 않으며,\n'
        '앱 삭제 시 모든 데이터가 함께 삭제됩니다.',
    'privacy_accept': '확인했어요',
    // Profile
    'edit_profile': '프로필 편집',
    'nickname': '닉네임',
    'nickname_hint': '새 닉네임을 입력하세요',
    'notification_settings': '알림 설정',
    'privacy_settings': '개인정보 설정',
    'language_settings': '언어 설정',
    'logout_confirm': '정말 로그아웃 하시겠어요?',
    'pins': '핀',
    'followers': '팔로워',
    'following': '팔로잉',
    'explorer': '탐험가',
    'no_pins': '아직 등록한 핀이 없어요\n+ 버튼을 눌러 첫 핀을 등록해보세요',
    'no_saved_pins': '저장된 핀이 없어요',
    'add_pin_to_map': '핀을 등록하면 지도에 표시돼요',
    'visited_places': '방문한 장소',
    'view_all': '전체보기',
    'my_pins_count': '내 핀 {n}개',
    'category_places': '{cat} 장소',
    // Feed
    'feed_tab_all': '전체',
    'feed_tab_following': '팔로잉',
    'my_pins': '내 핀',
    'community_feed': '커뮤니티 피드',
    'pinpler_feed': '핀플 피드',
    'no_following': '팔로잉한 핀플이 없습니다\n커뮤니티에서 핀플을 찾아보세요',
    'map_app_error': '지도 앱을 열 수 없습니다',
    'ai_info': 'AI 장소 정보',
    'ai_loading': 'AI 장소 정보를 불러오는 중...',
    'origin_history': '유래/역사',
    'highlights': '볼거리/특징',
    'best_time': '방문 시기',
    'visit_tip': '방문 팁',
    'my_pin_label': '내 핀',
    'pinpler': '핀플',
    // Create Pin
    'create_step_0': '사진 선택',
    'create_step_1': '위치 확인',
    'create_step_2': '핀 정보 입력',
    'create_step_3': '커뮤니티 공유',
    'create_step_4': '등록 완료',
    'photo_source_q': '사진을 어떻게 추가할까요?',
    'photo_source_desc': '카메라로 직접 찍거나 갤러리에서 선택하세요.',
    'camera': '카메라로 촬영',
    'camera_subtitle': '지금 이 위치에서 바로 찍기',
    'gallery': '갤러리에서 선택',
    'gallery_subtitle': 'GPS 정보가 포함된 사진만 등록 가능',
    'location_500m_info': '갤러리 사진의 촬영 장소와 현재 위치가 500m 이내여야 핀 등록이 가능합니다.',
    'verifying_location_msg': '위치를 확인하는 중...',
    'location_success': '위치 인증 성공',
    'location_fail': '위치 불일치',
    'no_gps_msg': '현재 위치를 가져올 수 없습니다.\nGPS 권한을 확인해주세요.',
    'no_exif_msg': 'EXIF 위치 정보가 없는 사진입니다.\n위치 정보가 포함된 사진을 선택해주세요.',
    'camera_verify_msg': '카메라로 촬영한 사진은 현재 위치에서\n찍힌 것으로 자동 인증됩니다.',
    'verify_success_msg': '위치 인증 성공!\n사진 촬영 장소와 현재 위치가 일치합니다.',
    'verify_fail_msg': '위치 불일치로 업로드가 제한됩니다.\n사진 촬영 장소({dist}m 떨어짐)에서만 핀을 등록할 수 있습니다.',
    'distance_to_location': '촬영 장소까지 {n}m',
    'category': '카테고리',
    'new_category': '새 카테고리',
    'create_category': '카테고리 만들기',
    'category_name_hint': '카테고리 이름 입력',
    'place_name': '장소 이름',
    'place_name_hint': '예: 북한산 백운대 정상',
    'description': '설명',
    'description_hint': '이 장소에 대해 자유롭게 설명해주세요.',
    'submit_pin': '핀 등록하기',
    'ai_fetch_location': 'AI로 장소 정보 가져오기',
    'ai_fetching': 'AI 장소 정보 불러오는 중...',
    'ai_enter_name_first': '먼저 장소 이름을 입력해주세요.',
    'use_ai_description': '이 내용으로 설명 채우기',
    'share_to_community_q': '커뮤니티에 공유할까요?',
    'share_subtitle': '멤버들과 이 핀을 함께 즐겨보세요',
    'no_community': '아직 참여한 커뮤니티가 없어요',
    'select_community': '커뮤니티를 선택하세요',
    'share_n_communities': '{n}개 커뮤니티에 공유하기',
    'pin_registered': '핀이 등록됐어요!',
    'pin_registered_desc': '지도에서 내 핀을 확인할 수 있어요.',
    // Community
    'community_title': '커뮤니티',
    'my_communities': '참여 중인 커뮤니티',
    'explore_communities': '탐색',
    'create_community': '커뮤니티 만들기',
    'join_community': '참여하기',
    'joined': '참여 중',
    'members': '멤버',
    'search_community': '커뮤니티 검색',
    'no_community_found': '검색 결과가 없어요',
    'no_joined_community': '참여한 커뮤니티가 없어요\n커뮤니티를 찾아 참여해보세요',
    // Email Auth
    'email_login': '로그인',
    'email_register': '회원가입',
    'email': '이메일',
    'password': '비밀번호',
    'password_confirm': '비밀번호 확인',
    'name': '이름',
    'email_hint': 'example@email.com',
    'password_hint': '비밀번호 입력',
    'name_hint': '닉네임 입력',
    'email_required': '이메일과 비밀번호를 입력해주세요',
    'wrong_credentials': '이메일 또는 비밀번호가 올바르지 않아요',
    'password_mismatch': '비밀번호가 일치하지 않아요',
    'password_too_short': '비밀번호는 6자 이상이어야 해요',
    'name_required': '이름을 입력해주세요',
    // Time
    'just_now': '방금 전',
    'minutes_ago': '{n}분 전',
    'hours_ago': '{n}시간 전',
    'days_ago': '{n}일 전',
  },

  'en': {
    // Navigation
    'nav_feed': 'Feed',
    'nav_map': 'Map',
    'nav_pin': 'Pin',
    'nav_community': 'Community',
    'nav_profile': 'Profile',
    // Common
    'cancel': 'Cancel',
    'save': 'Save',
    'confirm': 'Confirm',
    'or': 'or',
    'all': 'All',
    'share': 'Share',
    'skip': 'Skip',
    'next': 'Next',
    'retry': 'Retry',
    'done': 'Done',
    'add': 'Add',
    'logout': 'Log Out',
    'recommended': 'Recommended',
    'loading': 'Loading...',
    'directions': 'Directions',
    // Login
    'login_subtitle': 'Every moment, a map mark',
    'beta_test': 'BETA TEST',
    'try_now': 'Try Now',
    'try_now_desc': 'Experience all features without API key setup',
    'start_test': 'Start Testing',
    'start_with_social': 'Sign in with social account',
    'start_with_kakao': 'Continue with Kakao',
    'start_with_naver': 'Continue with Naver',
    'start_with_google': 'Continue with Google',
    'start_with_apple': 'Continue with Apple',
    'start_with_email': 'Continue with Email',
    'login_terms': 'By signing in, you agree to our Terms of Service and Privacy Policy',
    'provider_setup_title': '{provider} Integration Pending',
    'provider_setup_desc': 'API key setup required.\nPlease use test login for now.',
    // Privacy
    'privacy_title': 'Privacy Notice',
    'privacy_content':
        'Pinspot collects the following information:\n\n'
        '• Location: Used for pin registration and map display\n'
        '• Photos: Attached when registering pins (stored on device only)\n'
        '• Pin data: Stored only in device\'s internal storage\n\n'
        'Collected information is not transmitted to external servers,\n'
        'and all data is deleted when the app is uninstalled.',
    'privacy_accept': 'Got it',
    // Profile
    'edit_profile': 'Edit Profile',
    'nickname': 'Nickname',
    'nickname_hint': 'Enter new nickname',
    'notification_settings': 'Notification Settings',
    'privacy_settings': 'Privacy Settings',
    'language_settings': 'Language Settings',
    'logout_confirm': 'Are you sure you want to log out?',
    'pins': 'Pins',
    'followers': 'Followers',
    'following': 'Following',
    'explorer': 'Explorer',
    'no_pins': 'No pins yet\nTap + to add your first pin',
    'no_saved_pins': 'No saved pins',
    'add_pin_to_map': 'Your pins will appear on the map',
    'visited_places': 'Visited Places',
    'view_all': 'View All',
    'my_pins_count': 'My Pins: {n}',
    'category_places': '{cat} Places',
    // Feed
    'feed_tab_all': 'All',
    'feed_tab_following': 'Following',
    'my_pins': 'My Pins',
    'community_feed': 'Community Feed',
    'pinpler_feed': 'Pinpler Feed',
    'no_following': 'No following yet\nFind pinplers in community',
    'map_app_error': 'Cannot open map app',
    'ai_info': 'AI Place Info',
    'ai_loading': 'Loading AI place info...',
    'origin_history': 'Origin / History',
    'highlights': 'Highlights',
    'best_time': 'Best Time to Visit',
    'visit_tip': 'Visit Tips',
    'my_pin_label': 'My Pin',
    'pinpler': 'Pinpler',
    // Create Pin
    'create_step_0': 'Select Photo',
    'create_step_1': 'Verify Location',
    'create_step_2': 'Enter Pin Info',
    'create_step_3': 'Share to Community',
    'create_step_4': 'Registration Complete',
    'photo_source_q': 'How would you like to add a photo?',
    'photo_source_desc': 'Take a photo or choose from gallery.',
    'camera': 'Take with Camera',
    'camera_subtitle': 'Take photo right here',
    'gallery': 'Choose from Gallery',
    'gallery_subtitle': 'Only photos with GPS info can be registered',
    'location_500m_info': 'The photo\'s location must be within 500m of your current location to register a pin.',
    'verifying_location_msg': 'Verifying location...',
    'location_success': 'Location Verified',
    'location_fail': 'Location Mismatch',
    'no_gps_msg': 'Cannot get current location.\nPlease check GPS permissions.',
    'no_exif_msg': 'This photo has no EXIF location data.\nPlease select a photo with location info.',
    'camera_verify_msg': 'Photos taken with camera are\nautomatically verified at current location.',
    'verify_success_msg': 'Location verified!\nPhoto location matches your current position.',
    'verify_fail_msg': 'Upload restricted due to location mismatch.\nYou can only register a pin at the photo\'s location ({dist}m away).',
    'distance_to_location': '{n}m to photo location',
    'category': 'Category',
    'new_category': 'New Category',
    'create_category': 'Create Category',
    'category_name_hint': 'Enter category name',
    'place_name': 'Place Name',
    'place_name_hint': 'e.g. Bukhansan Peak',
    'description': 'Description',
    'description_hint': 'Describe this place freely.',
    'submit_pin': 'Register Pin',
    'ai_fetch_location': 'Get place info with AI',
    'ai_fetching': 'Loading AI place info...',
    'ai_enter_name_first': 'Please enter the place name first.',
    'use_ai_description': 'Use this as description',
    'share_to_community_q': 'Share to Community?',
    'share_subtitle': 'Let members enjoy this pin together',
    'no_community': 'No communities joined yet',
    'select_community': 'Select a community',
    'share_n_communities': 'Share to {n} communities',
    'pin_registered': 'Pin registered!',
    'pin_registered_desc': 'You can see your pin on the map.',
    // Community
    'community_title': 'Community',
    'my_communities': 'My Communities',
    'explore_communities': 'Explore',
    'create_community': 'Create Community',
    'join_community': 'Join',
    'joined': 'Joined',
    'members': 'Members',
    'search_community': 'Search communities',
    'no_community_found': 'No results found',
    'no_joined_community': 'No communities joined\nFind and join a community',
    // Email Auth
    'email_login': 'Log In',
    'email_register': 'Sign Up',
    'email': 'Email',
    'password': 'Password',
    'password_confirm': 'Confirm Password',
    'name': 'Name',
    'email_hint': 'example@email.com',
    'password_hint': 'Enter password',
    'name_hint': 'Enter nickname',
    'email_required': 'Please enter email and password',
    'wrong_credentials': 'Email or password is incorrect',
    'password_mismatch': 'Passwords do not match',
    'password_too_short': 'Password must be at least 6 characters',
    'name_required': 'Please enter your name',
    // Time
    'just_now': 'Just now',
    'minutes_ago': '{n}m ago',
    'hours_ago': '{n}h ago',
    'days_ago': '{n}d ago',
  },

  'ja': {
    // Navigation
    'nav_feed': 'フィード',
    'nav_map': 'マップ',
    'nav_pin': 'ピン',
    'nav_community': 'コミュニティ',
    'nav_profile': 'プロフィール',
    // Common
    'cancel': 'キャンセル',
    'save': '保存',
    'confirm': '確認',
    'or': 'または',
    'all': 'すべて',
    'share': '共有',
    'skip': 'スキップ',
    'next': '次へ',
    'retry': 'やり直す',
    'done': '完了',
    'add': '追加',
    'logout': 'ログアウト',
    'recommended': 'おすすめ',
    'loading': '読み込み中...',
    'directions': 'ルート案内',
    // Login
    'login_subtitle': '撮った瞬間、地図になる',
    'beta_test': 'ベータテスト',
    'try_now': 'すぐ体験する',
    'try_now_desc': 'APIキーなしで全機能を試せます',
    'start_test': 'テストで始める',
    'start_with_social': 'ソーシャルアカウントで開始',
    'start_with_kakao': 'カカオで始める',
    'start_with_naver': 'ネイバーで始める',
    'start_with_google': 'Googleで始める',
    'start_with_apple': 'Appleで始める',
    'start_with_email': 'メールで始める',
    'login_terms': 'ログインすることで利用規約とプライバシーポリシーに同意します',
    'provider_setup_title': '{provider}連携準備中',
    'provider_setup_desc': 'APIキーの設定が必要です。\n今はテストログインをご利用ください。',
    // Privacy
    'privacy_title': 'プライバシーについて',
    'privacy_content':
        'Pinspotは以下の情報を収集します:\n\n'
        '• 位置情報: ピン登録とマップ表示に使用\n'
        '• 写真: ピン登録時に添付（デバイスのみに保存）\n'
        '• ピンデータ: デバイスの内部ストレージのみに保管\n\n'
        '収集された情報は外部サーバーに送信されず、\n'
        'アプリ削除時にすべてのデータが削除されます。',
    'privacy_accept': '了解しました',
    // Profile
    'edit_profile': 'プロフィール編集',
    'nickname': 'ニックネーム',
    'nickname_hint': '新しいニックネームを入力',
    'notification_settings': '通知設定',
    'privacy_settings': 'プライバシー設定',
    'language_settings': '言語設定',
    'logout_confirm': '本当にログアウトしますか？',
    'pins': 'ピン',
    'followers': 'フォロワー',
    'following': 'フォロー中',
    'explorer': 'エクスプローラー',
    'no_pins': 'まだピンがありません\n+ボタンで最初のピンを登録しましょう',
    'no_saved_pins': '保存されたピンがありません',
    'add_pin_to_map': 'ピンを登録すると地図に表示されます',
    'visited_places': '訪問した場所',
    'view_all': '全て見る',
    'my_pins_count': 'マイピン {n}個',
    'category_places': '{cat}の場所',
    // Feed
    'feed_tab_all': 'すべて',
    'feed_tab_following': 'フォロー中',
    'my_pins': 'マイピン',
    'community_feed': 'コミュニティフィード',
    'pinpler_feed': 'ピンプルフィード',
    'no_following': 'フォロー中のピンプルはいません\nコミュニティでピンプルを見つけましょう',
    'map_app_error': '地図アプリを開けません',
    'ai_info': 'AI場所情報',
    'ai_loading': 'AI場所情報を読み込み中...',
    'origin_history': '由来・歴史',
    'highlights': '見どころ・特徴',
    'best_time': '訪問時期',
    'visit_tip': '訪問のヒント',
    'my_pin_label': 'マイピン',
    'pinpler': 'ピンプル',
    // Create Pin
    'create_step_0': '写真を選択',
    'create_step_1': '位置確認',
    'create_step_2': 'ピン情報入力',
    'create_step_3': 'コミュニティに共有',
    'create_step_4': '登録完了',
    'photo_source_q': '写真をどのように追加しますか？',
    'photo_source_desc': 'カメラで撮影するか、ギャラリーから選択してください。',
    'camera': 'カメラで撮影',
    'camera_subtitle': '今ここで撮影',
    'gallery': 'ギャラリーから選択',
    'gallery_subtitle': 'GPS情報付き写真のみ登録可能',
    'location_500m_info': 'ギャラリー写真の撮影場所と現在位置が500m以内である必要があります。',
    'verifying_location_msg': '位置を確認中...',
    'location_success': '位置認証成功',
    'location_fail': '位置不一致',
    'no_gps_msg': '現在位置を取得できません。\nGPS権限を確認してください。',
    'no_exif_msg': 'EXIFの位置情報がない写真です。\n位置情報が含まれた写真を選択してください。',
    'camera_verify_msg': 'カメラで撮影した写真は現在位置で\n自動認証されます。',
    'verify_success_msg': '位置認証成功！\n撮影場所と現在位置が一致しています。',
    'verify_fail_msg': '位置不一致のためアップロードが制限されます。\n撮影場所（{dist}m離れています）でのみピンを登録できます。',
    'distance_to_location': '撮影場所まで{n}m',
    'category': 'カテゴリー',
    'new_category': '新カテゴリー',
    'create_category': 'カテゴリーを作成',
    'category_name_hint': 'カテゴリー名を入力',
    'place_name': '場所の名前',
    'place_name_hint': '例：北漢山白雲台頂上',
    'description': '説明',
    'description_hint': 'この場所について自由に説明してください。',
    'submit_pin': 'ピンを登録する',
    'ai_fetch_location': 'AIで場所情報を取得',
    'ai_fetching': 'AI場所情報を読み込み中...',
    'ai_enter_name_first': '先に場所の名前を入力してください。',
    'use_ai_description': 'この内容で説明を埋める',
    'share_to_community_q': 'コミュニティに共有しますか？',
    'share_subtitle': 'メンバーとこのピンを一緒に楽しみましょう',
    'no_community': 'まだ参加したコミュニティがありません',
    'select_community': 'コミュニティを選択してください',
    'share_n_communities': '{n}つのコミュニティに共有する',
    'pin_registered': 'ピンが登録されました！',
    'pin_registered_desc': '地図でマイピンを確認できます。',
    // Community
    'community_title': 'コミュニティ',
    'my_communities': '参加中のコミュニティ',
    'explore_communities': '探索',
    'create_community': 'コミュニティを作成',
    'join_community': '参加する',
    'joined': '参加中',
    'members': 'メンバー',
    'search_community': 'コミュニティを検索',
    'no_community_found': '検索結果がありません',
    'no_joined_community': '参加したコミュニティがありません\nコミュニティを探して参加しましょう',
    // Email Auth
    'email_login': 'ログイン',
    'email_register': '会員登録',
    'email': 'メール',
    'password': 'パスワード',
    'password_confirm': 'パスワード確認',
    'name': '名前',
    'email_hint': 'example@email.com',
    'password_hint': 'パスワードを入力',
    'name_hint': 'ニックネームを入力',
    'email_required': 'メールとパスワードを入力してください',
    'wrong_credentials': 'メールまたはパスワードが正しくありません',
    'password_mismatch': 'パスワードが一致しません',
    'password_too_short': 'パスワードは6文字以上にしてください',
    'name_required': '名前を入力してください',
    // Time
    'just_now': 'たった今',
    'minutes_ago': '{n}分前',
    'hours_ago': '{n}時間前',
    'days_ago': '{n}日前',
  },

  'zh': {
    // Navigation
    'nav_feed': '动态',
    'nav_map': '地图',
    'nav_pin': '打卡',
    'nav_community': '社区',
    'nav_profile': '我的',
    // Common
    'cancel': '取消',
    'save': '保存',
    'confirm': '确定',
    'or': '或',
    'all': '全部',
    'share': '分享',
    'skip': '跳过',
    'next': '下一步',
    'retry': '重试',
    'done': '完成',
    'add': '添加',
    'logout': '退出登录',
    'recommended': '推荐',
    'loading': '加载中...',
    'directions': '导航',
    // Login
    'login_subtitle': '每一刻，皆是地标',
    'beta_test': '内测版',
    'try_now': '立即体验',
    'try_now_desc': '无需设置API密钥，体验所有功能',
    'start_test': '开始体验',
    'start_with_social': '使用社交账号登录',
    'start_with_kakao': '使用Kakao登录',
    'start_with_naver': '使用Naver登录',
    'start_with_google': '使用Google登录',
    'start_with_apple': '使用Apple登录',
    'start_with_email': '使用邮箱登录',
    'login_terms': '登录即表示您同意我们的服务条款和隐私政策',
    'provider_setup_title': '{provider}接入准备中',
    'provider_setup_desc': '需要设置API密钥。\n请暂时使用测试登录。',
    // Privacy
    'privacy_title': '隐私说明',
    'privacy_content':
        'Pinspot收集以下信息：\n\n'
        '• 位置信息：用于坐标登记和地图显示\n'
        '• 照片：登记坐标时附加（仅存储在设备上）\n'
        '• 坐标数据：仅保存在设备内部存储中\n\n'
        '收集的信息不会传输到外部服务器，\n'
        '卸载应用时所有数据将一并删除。',
    'privacy_accept': '我知道了',
    // Profile
    'edit_profile': '编辑资料',
    'nickname': '昵称',
    'nickname_hint': '请输入新昵称',
    'notification_settings': '通知设置',
    'privacy_settings': '隐私设置',
    'language_settings': '语言设置',
    'logout_confirm': '确定要退出登录吗？',
    'pins': '坐标',
    'followers': '粉丝',
    'following': '关注',
    'explorer': '探索者',
    'no_pins': '还没有坐标\n点击+添加第一个坐标',
    'no_saved_pins': '没有已保存的坐标',
    'add_pin_to_map': '添加坐标后将显示在地图上',
    'visited_places': '访问过的地方',
    'view_all': '查看全部',
    'my_pins_count': '我的坐标 {n}个',
    'category_places': '{cat}地点',
    // Feed
    'feed_tab_all': '全部',
    'feed_tab_following': '关注',
    'my_pins': '我的坐标',
    'community_feed': '社区动态',
    'pinpler_feed': 'Pinpler动态',
    'no_following': '还没有关注\n在社区中找到Pinpler',
    'map_app_error': '无法打开地图应用',
    'ai_info': 'AI地点信息',
    'ai_loading': '正在加载AI地点信息...',
    'origin_history': '起源/历史',
    'highlights': '亮点/特色',
    'best_time': '最佳游览时间',
    'visit_tip': '游览贴士',
    'my_pin_label': '我的坐标',
    'pinpler': 'Pinpler',
    // Create Pin
    'create_step_0': '选择照片',
    'create_step_1': '验证位置',
    'create_step_2': '输入坐标信息',
    'create_step_3': '分享到社区',
    'create_step_4': '登记完成',
    'photo_source_q': '如何添加照片？',
    'photo_source_desc': '拍摄照片或从相册选择。',
    'camera': '拍摄照片',
    'camera_subtitle': '在当前位置拍摄',
    'gallery': '从相册选择',
    'gallery_subtitle': '仅限含GPS信息的照片',
    'location_500m_info': '相册照片的拍摄地点需在当前位置500m以内才能登记坐标。',
    'verifying_location_msg': '正在验证位置...',
    'location_success': '位置验证成功',
    'location_fail': '位置不匹配',
    'no_gps_msg': '无法获取当前位置。\n请检查GPS权限。',
    'no_exif_msg': '该照片没有EXIF位置信息。\n请选择包含位置信息的照片。',
    'camera_verify_msg': '相机拍摄的照片将在当前位置\n自动完成验证。',
    'verify_success_msg': '位置验证成功！\n照片拍摄地点与当前位置一致。',
    'verify_fail_msg': '因位置不匹配，上传受限。\n只能在照片拍摄地点（距此{dist}m）登记坐标。',
    'distance_to_location': '距拍摄地点{n}m',
    'category': '类别',
    'new_category': '新建类别',
    'create_category': '创建类别',
    'category_name_hint': '输入类别名称',
    'place_name': '地点名称',
    'place_name_hint': '例：北汉山白云台顶',
    'description': '描述',
    'description_hint': '请自由描述这个地点。',
    'submit_pin': '登记坐标',
    'ai_fetch_location': '用AI获取地点信息',
    'ai_fetching': '正在加载AI地点信息...',
    'ai_enter_name_first': '请先输入地点名称。',
    'use_ai_description': '使用此内容填写描述',
    'share_to_community_q': '要分享到社区吗？',
    'share_subtitle': '与成员一起享受这个坐标',
    'no_community': '还没有加入任何社区',
    'select_community': '请选择社区',
    'share_n_communities': '分享到{n}个社区',
    'pin_registered': '坐标已登记！',
    'pin_registered_desc': '可以在地图上查看您的坐标。',
    // Community
    'community_title': '社区',
    'my_communities': '我加入的社区',
    'explore_communities': '探索',
    'create_community': '创建社区',
    'join_community': '加入',
    'joined': '已加入',
    'members': '成员',
    'search_community': '搜索社区',
    'no_community_found': '没有搜索结果',
    'no_joined_community': '还没有加入社区\n寻找并加入社区',
    // Email Auth
    'email_login': '登录',
    'email_register': '注册',
    'email': '邮箱',
    'password': '密码',
    'password_confirm': '确认密码',
    'name': '姓名',
    'email_hint': 'example@email.com',
    'password_hint': '请输入密码',
    'name_hint': '请输入昵称',
    'email_required': '请输入邮箱和密码',
    'wrong_credentials': '邮箱或密码不正确',
    'password_mismatch': '两次密码不一致',
    'password_too_short': '密码至少需要6个字符',
    'name_required': '请输入姓名',
    // Time
    'just_now': '刚刚',
    'minutes_ago': '{n}分钟前',
    'hours_ago': '{n}小时前',
    'days_ago': '{n}天前',
  },
};
