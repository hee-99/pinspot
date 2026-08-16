import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:pinspot/core/models/user_model.dart';

const String _googleWebClientId = '762402450188-k83an1bp12ufvrp65pq1kpmo7bjgskum.apps.googleusercontent.com';

final _googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? _googleWebClientId : null,
  serverClientId: kIsWeb ? null : _googleWebClientId,
  scopes: ['email', 'profile'],
);

// 카카오/네이버/구글/애플/이메일 로그인과 세션(SharedPreferences) 관리를 담당하는 인증 서비스
class AuthService {
  static const _userKey = 'auth_user';

  // ── Persistence ──────────────────────────────────────────────────────────────

  // 저장된 로그인 사용자 정보를 불러옴 (없으면 null)
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return UserModel.tryParse(prefs.getString(_userKey));
  }

  // 사용자 정보를 SharedPreferences에 JSON으로 저장
  static Future<void> _save(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // 저장된 세션을 지우고 각 소셜 SDK에서도 로그아웃 처리 (실패해도 무시)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
    try { await _googleSignIn.signOut(); } catch (_) {}
  }

  static Future<bool> isLoggedIn() async => (await getUser()) != null;

  // ── 테스트용 게스트 로그인 (키 발급 후 제거) ─────────────────────────────────
  // 소셜 로그인 없이 임시 게스트 계정을 만들어 즉시 로그인 처리
  static Future<UserModel> signInAsGuest() async {
    final user = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: '게스트',
      provider: 'guest',
    );
    await _save(user);
    return user;
  }

  // ── 카카오 로그인 ─────────────────────────────────────────────────────────────

  // 카카오톡 앱 로그인을 우선 시도하고, 실패/미설치 시 카카오계정 로그인으로 대체
  static Future<UserModel?> signInWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } on kakao.KakaoAuthException catch (e) {
          // 사용자가 거부했거나 알 수 없는 오류면 카카오계정 로그인으로 폴백
          if (e.error == kakao.AuthErrorCause.accessDenied ||
              e.error == kakao.AuthErrorCause.unknown) {
            await kakao.UserApi.instance.loginWithKakaoAccount();
          } else {
            rethrow;
          }
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final me = await kakao.UserApi.instance.me();
      final user = UserModel(
        id: me.id.toString(),
        name: me.kakaoAccount?.profile?.nickname ?? '카카오 유저',
        email: me.kakaoAccount?.email,
        provider: 'kakao',
        photoUrl: me.kakaoAccount?.profile?.thumbnailImageUrl,
      );
      await _save(user);
      return user;
    } on kakao.KakaoAuthException catch (e) {
      if (e.error == kakao.AuthErrorCause.accessDenied) return null;
      debugPrint('Kakao auth error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Kakao sign-in error: $e');
      rethrow;
    }
  }

  // ── 네이버 로그인 ─────────────────────────────────────────────────────────────

  // 네이버 SDK로 로그인하고 계정 정보를 UserModel로 변환해 저장
  static Future<UserModel?> signInWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();

      if (result.status != NaverLoginStatus.loggedIn) return null;

      final acc = result.account;
      final name = (acc?.name?.isNotEmpty == true)
          ? acc!.name!
          : (acc?.nickname?.isNotEmpty == true)
              ? acc!.nickname!
              : '네이버 유저';

      final user = UserModel(
        id: acc?.id ?? _uuid(),
        name: name,
        email: acc?.email?.isNotEmpty == true ? acc!.email : null,
        provider: 'naver',
        photoUrl: acc?.profileImage?.isNotEmpty == true ? acc!.profileImage : null,
      );
      await _save(user);
      return user;
    } catch (e) {
      debugPrint('Naver sign-in error: $e');
      rethrow;
    }
  }

  // ── 구글 로그인 ───────────────────────────────────────────────────────────────

  // 구글 로그인 SDK로 계정을 선택받고 UserModel로 변환해 저장
  static Future<UserModel?> signInWithGoogle() async {
    if (_googleWebClientId.startsWith('YOUR_')) {
      throw Exception('Google Client ID not configured');
    }
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // 사용자 취소

      final user = UserModel(
        id: account.id,
        name: account.displayName ?? '구글 유저',
        email: account.email,
        provider: 'google',
        photoUrl: account.photoUrl,
      );
      await _save(user);
      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────

  // Apple ID로 로그인하고(nonce로 재전송 공격 방지) UserModel로 변환해 저장
  static Future<UserModel?> signInWithApple() async {
    if (!await SignInWithApple.isAvailable()) return null;

    try {
      final nonce = _generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );

      final fullName = [credential.givenName, credential.familyName]
          .where((n) => n != null && n.isNotEmpty)
          .join(' ');

      final user = UserModel(
        id: credential.userIdentifier ?? _uuid(),
        name: fullName.isNotEmpty ? fullName : '애플 유저',
        email: credential.email,
        provider: 'apple',
      );
      await _save(user);
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      debugPrint('Apple sign-in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      rethrow;
    }
  }

  // ── 이메일 자체 로그인 ────────────────────────────────────────────────────────

  static const _emailAccountsKey = 'email_accounts';

  // 로컬에 저장된 이메일 계정 목록에서 이메일/비밀번호 해시를 대조해 로그인
  // salt가 없는 구(舊) 계정(무salt SHA-256 시절 가입)은 레거시 해시로 한 번 검증한 뒤
  // 로그인 성공 시 salt를 붙여 자동으로 마이그레이션한다.
  static Future<UserModel?> signInWithEmail(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailAccountsKey);
    if (raw == null) return null;
    final accounts = json.decode(raw) as Map<String, dynamic>;
    final key = email.toLowerCase().trim();
    if (!accounts.containsKey(key)) return null;
    final acct = accounts[key] as Map<String, dynamic>;
    final salt = acct['salt'] as String?;

    if (salt != null) {
      if (acct['passwordHash'] != _hashPassword(password, salt)) return null;
    } else {
      final legacyHash = sha256.convert(utf8.encode(password)).toString();
      if (acct['passwordHash'] != legacyHash) return null;
      final newSalt = _generateSalt();
      accounts[key] = {
        ...acct,
        'salt': newSalt,
        'passwordHash': _hashPassword(password, newSalt),
      };
      await prefs.setString(_emailAccountsKey, json.encode(accounts));
    }

    final user = UserModel(
      id: 'email_$key',
      name: acct['name'] as String,
      email: email.trim(),
      provider: 'email',
      isAdmin: acct['isAdmin'] as bool? ?? false,
    );
    await _save(user);
    return user;
  }

  // 새 이메일 계정을 로컬 저장소에 등록 (비밀번호는 salt + SHA-256 해시로 저장)
  static Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailAccountsKey);
    final accounts = raw != null
        ? json.decode(raw) as Map<String, dynamic>
        : <String, dynamic>{};
    final key = email.toLowerCase().trim();
    final salt = _generateSalt();
    accounts[key] = {
      'name': name.trim(),
      'salt': salt,
      'passwordHash': _hashPassword(password, salt),
    };
    await prefs.setString(_emailAccountsKey, json.encode(accounts));
    final user = UserModel(
      id: 'email_$key',
      name: name.trim(),
      email: email.trim(),
      provider: 'email',
    );
    await _save(user);
    return user;
  }

  // 현재 로그인된 계정의 관리자 모드를 켜고 끔 (설정 화면의 숨겨진 제스처로 진입)
  // 이메일 계정은 email_accounts에도 반영해 재로그인 후에도 유지되도록 함
  static Future<UserModel?> toggleAdminMode() async {
    final current = await getUser();
    if (current == null) return null;
    final updated = UserModel(
      id: current.id,
      name: current.name,
      email: current.email,
      provider: current.provider,
      photoUrl: current.photoUrl,
      localPhotoPath: current.localPhotoPath,
      isAdmin: !current.isAdmin,
    );
    await _save(updated);

    if (current.provider == 'email' && current.email != null) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_emailAccountsKey);
      if (raw != null) {
        final accounts = json.decode(raw) as Map<String, dynamic>;
        final key = current.email!.toLowerCase().trim();
        if (accounts.containsKey(key)) {
          final acct = accounts[key] as Map<String, dynamic>;
          accounts[key] = {...acct, 'isAdmin': updated.isAdmin};
          await prefs.setString(_emailAccountsKey, json.encode(accounts));
        }
      }
    }
    return updated;
  }

  // 현재 로그인된 사용자의 닉네임/프로필 사진 경로를 갱신
  static Future<UserModel?> updateProfile({required String name, String? localPhotoPath}) async {
    final current = await getUser();
    if (current == null) return null;
    final updated = UserModel(
      id: current.id,
      name: name.trim().isEmpty ? current.name : name.trim(),
      email: current.email,
      provider: current.provider,
      photoUrl: current.photoUrl,
      localPhotoPath: localPhotoPath ?? current.localPhotoPath,
      isAdmin: current.isAdmin,
    );
    await _save(updated);
    return updated;
  }

  // 해당 이메일로 이미 가입된 계정이 있는지 확인 (회원가입 시 중복 체크)
  static Future<bool> emailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailAccountsKey);
    if (raw == null) return false;
    final accounts = json.decode(raw) as Map<String, dynamic>;
    return accounts.containsKey(email.toLowerCase().trim());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  // Apple 로그인 재전송 공격 방지를 위한 랜덤 nonce 문자열 생성
  static String _generateNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // 이메일 비밀번호용 랜덤 salt 생성 (레인보우 테이블 공격 방지)
  static String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    return base64UrlEncode(List<int>.generate(length, (_) => rand.nextInt(256)));
  }

  static String _hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _uuid() => DateTime.now().millisecondsSinceEpoch.toString();
}
