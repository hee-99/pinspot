import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
  }

  static Future<bool> isLoggedIn() async => (await getUser()) != null;

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

  // ── Kakao Sign-In (stub — needs kakao_flutter_sdk_user + native setup) ────
  //
  // 1. pubspec.yaml 에 추가:
  //      kakao_flutter_sdk_user: ^1.9.0
  // 2. https://developers.kakao.com/console 에서 앱 등록 후 네이티브 앱 키 발급
  // 3. AndroidManifest.xml 에 KakaoActivity / URL scheme 추가
  // 4. Info.plist 에 URL scheme 추가
  // 준비 완료 후 아래 stub를 실제 구현으로 교체:
  //
  //   import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
  //   final token = await UserApi.instance.loginWithKakaoAccount();
  //   final user = await UserApi.instance.me();
  //   ...
  static Future<UserModel?> signInWithKakao() async {
    // TODO: 카카오 SDK 설정 후 구현
    return null;
  }

  // ── Naver Sign-In (stub — needs flutter_naver_login + native setup) ───────
  //
  // 1. pubspec.yaml 에 추가:
  //      flutter_naver_login: ^1.8.0
  // 2. https://developers.naver.com/apps 에서 앱 등록 후 클라이언트 ID/Secret 발급
  // 3. AndroidManifest.xml 에 clientId / clientSecret / appName 추가
  // 4. Info.plist 에 URL scheme 추가
  // 준비 완료 후 아래 stub를 실제 구현으로 교체:
  //
  //   import 'package:flutter_naver_login/flutter_naver_login.dart';
  //   final result = await FlutterNaverLogin.logIn();
  //   ...
  static Future<UserModel?> signInWithNaver() async {
    // TODO: 네이버 SDK 설정 후 구현
    return null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _generateNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _uuid() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
