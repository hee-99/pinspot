import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
    // 카카오 토큰도 만료 처리
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {}
  }

  static Future<bool> isLoggedIn() async => (await getUser()) != null;

  // ── 카카오 로그인 ─────────────────────────────────────────────────────────────

  static Future<UserModel?> signInWithKakao() async {
    try {
      // 카카오톡 앱이 설치돼 있으면 앱으로, 없으면 브라우저로
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } on kakao.KakaoAuthException catch (e) {
          // 카카오톡에서 취소하거나 실패하면 브라우저로 재시도
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

      // 로그인 성공 → 사용자 정보 가져오기
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
      if (e.error == kakao.AuthErrorCause.accessDenied) return null; // 사용자 취소
      debugPrint('Kakao auth error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Kakao sign-in error: $e');
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

  // ── Naver (stub) ───────────────────────────────────────────────────────────
  // TODO: flutter_naver_login 패키지 + 네이버 개발자 센터 앱 등록 후 구현
  static Future<UserModel?> signInWithNaver() async => null;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _uuid() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
