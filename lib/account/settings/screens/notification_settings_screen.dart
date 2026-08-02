import 'package:flutter/material.dart';
import 'package:pinspot/core/l10n/app_localizations.dart';
import 'package:pinspot/account/settings/services/notification_settings_service.dart';
import 'package:pinspot/design/theme/app_theme.dart';
import 'package:pinspot/design/theme/app_colors.dart';

// 알림 설정 화면 — 팔로우 핀 등록 알림 on/off 토글 + 알림함(현재는 빈 상태만 표시)
// 서버가 없는 로컬 앱이라 실제 알림 발송 로직은 없고, 토글 값만 저장됨 (추후 백엔드 연동 시 이 값을 사용)
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          l.notificationSettings,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            child: _FollowPinAlertTile(l: l),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              l.notificationInboxTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral900,
              ),
            ),
          ),
          _SectionCard(
            child: _NotificationEmptyState(l: l),
          ),
        ],
      ),
    );
  }
}

// 팔로우한 사람 핀 등록 알림 on/off 스위치 항목 (전역 서비스 값에 연결, 토글 즉시 저장)
class _FollowPinAlertTile extends StatelessWidget {
  final AppLocalizations l;
  const _FollowPinAlertTile({required this.l});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NotificationSettingsService.followPinAlertNotifier,
      builder: (context, enabled, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          title: Text(
            l.notificationFollowPinTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.notificationFollowPinDesc,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ),
          trailing: Switch(
            value: enabled,
            activeColor: AppColors.primary,
            onChanged: (v) => NotificationSettingsService.setFollowPinAlert(v),
          ),
        );
      },
    );
  }
}

// 알림이 하나도 없을 때 보여주는 빈 상태 위젯 (아직 실제 알림 발생 로직이 없어 항상 이 상태)
class _NotificationEmptyState extends StatelessWidget {
  final AppLocalizations l;
  const _NotificationEmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.neutral400,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.notificationEmptyTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.notificationEmptyDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral400, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// 설정 항목을 감싸는 흰색 카드 컨테이너 (다른 설정 화면들과 톤을 맞춘 그림자/라운드 스타일)
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
