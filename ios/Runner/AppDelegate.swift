import Flutter
import UIKit
import GoogleMaps
import NaverThirdPartyLogin

// ★ YOUR_NAVER_CLIENT_ID / YOUR_NAVER_CLIENT_SECRET 을 실제 값으로 교체하세요
private let naverClientId     = "YOUR_NAVER_CLIENT_ID"
private let naverClientSecret = "YOUR_NAVER_CLIENT_SECRET"
private let naverUrlScheme    = "naverYOUR_NAVER_CLIENT_ID"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAyEl5Vc30X00H4SX6Px6CdxvLTeDPqJFA")

    // 네이버 로그인 SDK 초기화
    let naver = NaverThirdPartyLoginConnection.getSharedInstance()
    naver?.isNaverAppOauthEnable = true   // 네이버 앱으로 로그인
    naver?.isInAppOauthEnable    = true   // 브라우저 로그인 폴백
    naver?.serviceUrlScheme      = naverUrlScheme
    naver?.consumerKey           = naverClientId
    naver?.consumerSecret        = naverClientSecret
    naver?.appName               = "Pinspot"

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 네이버 / 카카오 OAuth 콜백 URL 처리
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if NaverThirdPartyLoginConnection.getSharedInstance()
        .application(app, open: url, options: options) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
