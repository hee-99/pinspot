import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../models/user_model.dart';

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
    // 각 SDK 토큰도 만료 처리
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
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
      final name = acc.name.isNotEmpty
          ? acc.name
          : acc.nickname.isNotEmpty
              ? acc.nickname
              : '네이버 유저';

      final user = UserModel(
        id: acc.id,
        name: name,
        email: acc.email.isNotEmpty ? acc.email : null,
        provider: 'naver',
        photoUrl: acc.profileImage.isNotEmpty ? acc.profileImage : null,
      );
      await _save(user);
      return user;
    } catch (e) {
      debugPrint('Naver sign-in error: $e');
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _uuid() => DateTime.now().millisecondsSinceEpoch.toString();
}
