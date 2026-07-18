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
import '../models/user_model.dart';

const String _googleWebClientId = '762402450188-k83an1bp12ufvrp65pq1kpmo7bjgskum.apps.googleusercontent.com';

final _googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? _googleWebClientId : null,
  serverClientId: kIsWeb ? null : _googleWebClientId,
  scopes: ['email', 'profile'],
);

class AuthService {
  static const _userKey = 'auth_user';

  // ── Persistence ──────────────────────────────────────────────────────────────

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return UserModel.tryParse(prefs.getString(_userKey));
  }

  static Future<void> _save(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
    try { await _googleSignIn.signOut(); } catch (_) {}
  }

  static Future<bool> isLoggedIn() async => (await getUser()) != null;

  // ── 테스트용 게스트 로그인 (키 발급 후 제거) ─────────────────────────────────
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

  static Future<UserModel?> signInWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } on kakao.KakaoAuthException catch (e) {
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

  static Future<UserModel?> signInWithEmail(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailAccountsKey);
    if (raw == null) return null;
    final accounts = json.decode(raw) as Map<String, dynamic>;
    final key = email.toLowerCase().trim();
    if (!accounts.containsKey(key)) return null;
    final acct = accounts[key] as Map<String, dynamic>;
    final inputHash = sha256.convert(utf8.encode(password)).toString();
    if (acct['passwordHash'] != inputHash) return null;
    final user = UserModel(
      id: 'email_$key',
      name: acct['name'] as String,
      email: email.trim(),
      provider: 'email',
    );
    await _save(user);
    return user;
  }

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
    accounts[key] = {
      'name': name.trim(),
      'passwordHash': sha256.convert(utf8.encode(password)).toString(),
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
    );
    await _save(updated);
    return updated;
  }

  static Future<bool> emailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailAccountsKey);
    if (raw == null) return false;
    final accounts = json.decode(raw) as Map<String, dynamic>;
    return accounts.containsKey(email.toLowerCase().trim());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _uuid() => DateTime.now().millisecondsSinceEpoch.toString();
}
