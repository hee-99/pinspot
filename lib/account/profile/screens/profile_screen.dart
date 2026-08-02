import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinspot/core/l10n/app_localizations.dart';
import 'package:pinspot/account/settings/services/locale_service.dart';
import 'package:pinspot/design/theme/app_theme.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/core/models/pin_model.dart';
import 'package:pinspot/core/models/pinpler_tier.dart';
import 'package:pinspot/core/models/user_model.dart';
import 'package:pinspot/account/auth/services/auth_service.dart';
import 'package:pinspot/features/pin/services/pin_service.dart';
import 'package:pinspot/design/utils/marker_builder.dart';
import 'package:pinspot/account/auth/screens/login_screen.dart';
import 'package:pinspot/account/settings/screens/language_test_screen.dart';
import 'package:pinspot/account/settings/screens/notification_settings_screen.dart';
import 'package:pinspot/features/tigo/screens/tigo_closet_screen.dart';
import 'package:pinspot/features/home/screens/home_content_screen.dart';

// 프로필 화면 — 유저 정보 헤더 + 티고 바로가기 + 3탭(전체/내 지도/저장됨)으로 구성
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  UserModel? _user;
  List<PinModel> _pins = [];
  bool _loading = true;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
    _loadMapStyle();
    // 다른 화면에서 핀이 추가/변경되면 프로필도 다시 로드하도록 전역 알림자 구독
    PinRefreshNotifier.instance.addListener(_load);
  }

  @override
  void dispose() {
    _tabController.dispose();
    PinRefreshNotifier.instance.removeListener(_load);
    super.dispose();
  }

  // 로그인 유저 정보와 저장된 핀 목록을 불러와 상태를 갱신
  Future<void> _load() async {
    final user = await AuthService.getUser();
    final pins = await PinService.getPins();
    if (mounted) setState(() { _user = user; _pins = pins; _loading = false; });
  }

  // 내 지도 탭에서 사용할 구글맵 커스텀 스타일 JSON을 로드
  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  // 로그아웃 확인 다이얼로그를 띄우고, 확인 시 세션 종료 후 로그인 화면으로 이동
  Future<void> _logout() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.logout, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(l.logout, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // 닉네임/프로필 사진을 수정하는 바텀시트를 열고 저장 시 AuthService에 반영
  Future<void> _editProfile() async {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    String? newPhotoPath = _user?.localPhotoPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
                ),
                Text(l.editProfile, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
                    if (file != null) setSheetState(() => newPhotoPath = file.path);
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primary,
                        backgroundImage: newPhotoPath != null && !kIsWeb
                            ? FileImage(File(newPhotoPath!)) : null,
                        child: (newPhotoPath == null || kIsWeb)
                            ? (_user?.photoUrl != null
                                ? null
                                : const Icon(Icons.person, size: 48, color: Colors.white))
                            : null,
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: l.nickname,
                    hintText: l.nicknameHint,
                    filled: true,
                    fillColor: _kBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await AuthService.updateProfile(
                        name: nameCtrl.text.trim().isEmpty ? (_user?.name ?? '') : nameCtrl.text.trim(),
                        localPhotoPath: newPhotoPath,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (updated != null && mounted) setState(() => _user = updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(l.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 지원 언어 목록을 바텀시트로 보여주고 선택 시 LocaleService로 언어 변경
  void _showLanguagePicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(l.languageSettings,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...AppLocalizations.languageNames.entries.map((entry) {
              final code = entry.key;
              final name = entry.value;
              final flag = AppLocalizations.languageFlags[code] ?? '';
              final isCurrent = LocaleService.currentCode == code;
              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 24)),
                title: Text(name,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isCurrent ? AppTheme.primary : AppTheme.textPrimary,
                    )),
                trailing: isCurrent
                    ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  LocaleService.setLocale(code);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 설정 메뉴(프로필 수정/언어/번역테스트/알림/개인정보/로그아웃)를 바텀시트로 표시
  void _showSettings() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SettingsItem(
              icon: Icons.person_outline,
              label: l.editProfile,
              onTap: () { Navigator.pop(context); _editProfile(); },
            ),
            _SettingsItem(
              icon: Icons.language,
              label: l.languageSettings,
              onTap: () { Navigator.pop(context); _showLanguagePicker(); },
            ),
            _SettingsItem(
              icon: Icons.translate,
              label: '번역 테스트',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LanguageTestScreen()));
              },
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              label: l.notificationSettings,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
              },
            ),
            _SettingsItem(
              icon: Icons.lock_outline,
              label: l.privacySettings,
              onTap: () => Navigator.pop(context),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            _SettingsItem(
              icon: Icons.logout,
              label: l.logout,
              color: const Color(0xFFC62828),
              onTap: () { Navigator.pop(context); _logout(); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 헤더(고정 스크롤) + 탭바 + 탭별 콘텐츠(TabBarView)를 NestedScrollView로 구성
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          _user?.name ?? l.navProfile,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kText1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _kText2),
            onPressed: _showSettings,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: _user, pinCount: _pins.length),
          ),
          SliverToBoxAdapter(
            child: _TigoQuickAccess(),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabController: _tabController),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ContentTab(pins: _pins),
            _MyMapTab(pins: _pins, mapStyle: _mapStyle),
            _SavedTab(pins: _pins),
          ],
        ),
      ),
    );
  }
}

// ─── 색상 토큰 (피드·커뮤니티와 통일) ─────────────────────────────────────────
const _kBg    = Color(0xFFF5F3EE);
const _kCard  = Color(0xFFFFFFFF);
const _kText1 = Color(0xFF1C1C1E);
const _kText2 = Color(0xFF6B7280);
const _kText3 = Color(0xFFC9C5BE);

// ─── 설정 아이템 ──────────────────────────────────────────────────────────────

// 설정 바텀시트의 개별 메뉴 행 (아이콘+라벨+화살표)
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: c)),
      trailing: Icon(Icons.chevron_right, color: c.withValues(alpha: 0.4), size: 20),
      onTap: onTap,
    );
  }
}

// ─── 프로필 헤더 ───────────────────────────────────────────────────────────────

// 프로필 상단 헤더 — 커버 배너, 아바타, 닉네임/등급/로그인 provider, 통계, 수정/공유 버튼
class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final int pinCount;

  const _ProfileHeader({required this.user, required this.pinCount});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final providerLabel = switch (user?.provider) {
      'kakao'  => 'Kakao',
      'naver'  => 'Naver',
      'google' => 'Google',
      'apple'  => 'Apple',
      'email'  => l.email,
      _        => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 커버 배너 ─────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A1605), AppColors.primaryDark, AppColors.primary],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0.06,
                    child: CustomPaint(painter: _DotGridPainter()),
                  ),
                ],
              ),
            ),
            // 아바타 (커버와 겹침)
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14)],
                ),
                child: Stack(
                  children: [
                    _buildAvatar(),
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── 유저 정보 ──────────────────────────────────────────────
        Container(
          color: _kCard,
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    user?.name ?? l.explorer,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 7),
                _TierBadge(tier: PinplerTierX.fromPinCount(pinCount)),
                if (providerLabel != null) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(providerLabel,
                        style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              if (user?.email != null) ...[
                const SizedBox(height: 3),
                Text(user!.email!,
                    style: const TextStyle(color: _kText2, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 18),

              // ── 통계 칩 ──────────────────────────────────────────
              Row(children: [
                _StatChip(label: l.pins, value: '$pinCount'),
                const SizedBox(width: 10),
                _StatChip(label: l.followers, value: '0'),
                const SizedBox(width: 10),
                _StatChip(label: l.following, value: '0'),
              ]),

              const SizedBox(height: 14),

              // ── 버튼 ─────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final state = context.findAncestorStateOfType<_ProfileScreenState>();
                      await state?._editProfile();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l.editProfile, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDEE1D9)),
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l.share),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  // 로컬 사진 → 네트워크 사진 → 기본 아이콘 순으로 우선순위를 두어 아바타를 렌더링
  Widget _buildAvatar() {
    if (user?.localPhotoPath != null && !kIsWeb) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: FileImage(File(user!.localPhotoPath!)),
        backgroundColor: AppTheme.primary,
        onBackgroundImageError: (_, __) {},
      );
    }
    if (user?.photoUrl != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(user!.photoUrl!),
        backgroundColor: AppTheme.primary,
      );
    }
    return const CircleAvatar(
      radius: 44,
      backgroundColor: AppTheme.primary,
      child: Icon(Icons.person, size: 44, color: Colors.white),
    );
  }
}

// 핀플 등급(새싹/액티브/베테랑/마스터) 배지 위젯
class _TierBadge extends StatelessWidget {
  final PinplerTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tier.badgeEmoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            tier.label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tier.color),
          ),
        ],
      ),
    );
  }
}

// 커버 배너 위에 은은하게 깔리는 점 격자 패턴을 그리는 커스텀 페인터
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    const s = 18.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        canvas.drawCircle(Offset(x, y), 1.5, p);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// 핀/팔로워/팔로잉 수를 보여주는 통계 칩 위젯
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _kText1, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _kText2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


// ─── 티고 바로가기 (도감 · 꾸미기) ────────────────────────────────────────────────

// 티고(마스코트) 도감·꾸미기 화면으로 이동하는 바로가기 카드 2개를 보여주는 영역
class _TigoQuickAccess extends StatelessWidget {
  const _TigoQuickAccess();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _QuickCard(
            icon: '📖',
            label: '도감',
            subtitle: '티고의 기록',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HomeContentScreen())),
          ),
          const SizedBox(width: 10),
          _QuickCard(
            icon: '🐯',
            label: '티고 꾸미기',
            subtitle: '아이템 장착',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TigoClosetScreen())),
          ),
        ],
      ),
    );
  }
}

// 티고 바로가기 카드 하나(아이콘+라벨+부제)
class _QuickCard extends StatelessWidget {
  final String icon, label, subtitle;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.subtitle, required this.onTap});

  static const _orange = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE9E3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kText1)),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: _kText2)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: _kText3),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 탭바 ──────────────────────────────────────────────────────────────────────

// NestedScrollView 상단에 고정되는 3탭(전체/내 지도/저장됨) 탭바 델리게이트
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  const _TabBarDelegate({required this.tabController});

  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _kCard,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: _kText3,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        dividerColor: _kBg,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined, size: 20)),
          Tab(icon: Icon(Icons.map_outlined, size: 20)),
          Tab(icon: Icon(Icons.bookmark_outline, size: 20)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─── 탭 1: 내 핀 그리드 ──────────────────────────────────────────────────────

// 내 핀을 카테고리별로 필터링해 3열 그리드로 보여주는 탭
class _ContentTab extends StatefulWidget {
  final List<PinModel> pins;
  const _ContentTab({required this.pins});

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  String _selectedCategory = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 최초 진입 시 "전체" 카테고리로 기본 선택
    if (_selectedCategory.isEmpty) {
      _selectedCategory = AppLocalizations.of(context).all;
    }
  }

  // 보유한 핀들의 카테고리 목록(중복 제거, 정렬)
  List<String> get _categories {
    final cats = widget.pins.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  }

  // 선택된 카테고리에 해당하는 핀만 필터링
  List<PinModel> get _filtered {
    final allKey = AppLocalizations.of(context).all;
    if (_selectedCategory == allKey) return widget.pins;
    return widget.pins.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allKey = l.all;

    if (_selectedCategory.isEmpty) _selectedCategory = allKey;

    if (widget.pins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(l.noPins,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kText2, fontSize: 14, height: 1.6)),
          ],
        ),
      );
    }

    final allCategories = [allKey, ..._categories];

    return Column(
      children: [
        Container(
          color: _kCard,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: allCategories.map((cat) {
                final isSelected = cat == _selectedCategory;
                final count = cat == allKey
                    ? widget.pins.length
                    : widget.pins.where((p) => p.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? _kText1 : _kBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? null : const [BoxShadow(color: Color(0x09000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        '$cat  $count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _kText2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length}개',
              style: const TextStyle(fontSize: 12, color: _kText2, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, index) => _PinThumbnail(pin: _filtered[index]),
          ),
        ),
      ],
    );
  }
}

// 그리드에 표시되는 핀 썸네일 (사진 + 카테고리 라벨)
class _PinThumbnail extends StatelessWidget {
  final PinModel pin;
  const _PinThumbnail({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPhoto(),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pin.category,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // 사진 경로가 있으면 이미지를, 없거나 로드 실패 시 플레이스홀더를 표시
  Widget _buildPhoto() {
    if (pin.photoPath != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(pin.photoPath!), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder()),
      );
    }
    return _placeholder();
  }

  // 사진이 없는 핀을 위한 기본 아이콘 플레이스홀더
  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Icon(Icons.location_on, size: 28, color: AppColors.primary)),
    );
  }
}

// ─── 탭 2: 나의 지도 ───────────────────────────────────────────────────────────

// 내 핀들을 구글맵 위에 마커로 표시하는 탭 (카테고리 필터 + 자동 화면맞춤)
class _MyMapTab extends StatefulWidget {
  final List<PinModel> pins;
  final String? mapStyle;
  const _MyMapTab({required this.pins, required this.mapStyle});

  @override
  State<_MyMapTab> createState() => _MyMapTabState();
}

class _MyMapTabState extends State<_MyMapTab> {
  final _controller = Completer<GoogleMapController>();
  String _selectedCategory = '';
  Map<String, BitmapDescriptor> _markerIcons = {};

  List<String> get _categories {
    final cats = widget.pins.map((p) => p.category).toSet().toList()..sort();
    final allKey = AppLocalizations.of(context).all;
    return [allKey, ...cats];
  }

  List<PinModel> get _filtered {
    final allKey = AppLocalizations.of(context).all;
    if (_selectedCategory.isEmpty || _selectedCategory == allKey) return widget.pins;
    return widget.pins.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory.isEmpty) {
      _selectedCategory = AppLocalizations.of(context).all;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(_MyMapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pins.length != oldWidget.pins.length && _controller.isCompleted) {
      _fitBounds();
    }
    if (widget.pins != oldWidget.pins) _loadMarkers();
  }

  // 핀 사진을 이용해 커스텀 마커 아이콘들을 미리 생성해둠
  Future<void> _loadMarkers() async {
    final icons = <String, BitmapDescriptor>{};
    for (final pin in widget.pins) {
      if (pin.photoPath != null) {
        icons[pin.id] = await MarkerBuilder.buildPhotoMarker(pin.photoPath!);
      }
    }
    if (mounted) setState(() => _markerIcons = icons);
  }

  // 필터링된 핀들이 모두 보이도록 카메라를 이동 (핀 1개면 확대, 여러개면 경계에 맞춤)
  Future<void> _fitBounds() async {
    final pins = _filtered;
    if (pins.isEmpty) return;
    final ctrl = await _controller.future;
    if (pins.length == 1) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pins.first.lat, pins.first.lng), 13));
      return;
    }
    double s = pins.first.lat, n = pins.first.lat;
    double w = pins.first.lng, e = pins.first.lng;
    for (final p in pins) {
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
    }
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)), 80));
  }

  // 핀 목록을 구글맵 Marker 집합으로 변환 (커스텀 아이콘 없으면 기본 초록 마커 사용)
  Set<Marker> _buildMarkers(List<PinModel> pins) => pins.map((pin) => Marker(
    markerId: MarkerId(pin.id),
    position: LatLng(pin.lat, pin.lng),
    infoWindow: InfoWindow(title: pin.title, snippet: pin.category),
    icon: _markerIcons[pin.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  )).toSet();

  // 필터링된 핀들의 평균 좌표를 초기 지도 중심으로 사용 (핀이 없으면 서울시청 기본값)
  LatLng get _defaultCenter {
    final pins = _filtered.isNotEmpty ? _filtered : widget.pins;
    if (pins.isEmpty) return const LatLng(37.5665, 126.9780);
    return LatLng(
      pins.map((p) => p.lat).reduce((a, b) => a + b) / pins.length,
      pins.map((p) => p.lng).reduce((a, b) => a + b) / pins.length,
    );
  }

  // 카테고리 필터 선택 시 상태를 갱신하고 지도 화면을 다시 맞춤
  void _onCategorySelected(String cat) {
    setState(() => _selectedCategory = cat);
    if (_controller.isCompleted) _fitBounds();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allKey = l.all;
    if (_selectedCategory.isEmpty) _selectedCategory = allKey;

    final filtered = _filtered;
    const filterBarHeight = 47.0;
    const placeChipsHeight = 116.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height - 160;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 11.5),
                  onMapCreated: (ctrl) {
                    _controller.complete(ctrl);
                    if (filtered.isNotEmpty) _fitBounds();
                  },
                  style: widget.mapStyle,
                  markers: _buildMarkers(filtered),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              // 카테고리 필터 칩
              Positioned(
                top: 0, left: 0, right: 0, height: filterBarHeight,
                child: Container(
                  color: _kCard,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        final count = cat == allKey
                            ? widget.pins.length
                            : widget.pins.where((p) => p.category == cat).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _onCategorySelected(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? _kText1 : _kBg,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected ? null : const [BoxShadow(color: Color(0x09000000), blurRadius: 6, offset: Offset(0, 2))],
                              ),
                              child: Text(
                                widget.pins.isEmpty ? cat : '$cat  $count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : _kText2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              if (widget.pins.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: filterBarHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_location_alt_outlined, size: 36, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(l.addPinToMap,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: filterBarHeight + 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCategory == allKey
                                ? l.myPinsCount(widget.pins.length)
                                : '$_selectedCategory ${filtered.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (filtered.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _fitBounds,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fit_screen_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(l.viewAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (filtered.isNotEmpty)
                Positioned(
                  bottom: 0, left: 0, right: 0, height: placeChipsHeight,
                  child: Container(
                    color: _kCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text(
                            _selectedCategory == allKey
                                ? l.visitedPlaces
                                : l.categoryPlaces(_selectedCategory),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) => _PlaceChip(pin: filtered[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// 지도 하단 가로 스크롤 목록에 표시되는 장소 칩 (카테고리 + 제목)
class _PlaceChip extends StatelessWidget {
  final PinModel pin;
  const _PlaceChip({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              pin.category,
              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pin.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── 탭 3: 저장됨 ──────────────────────────────────────────────────────────────

// 저장(북마크)한 핀들을 그리드로 보여주는 탭
class _SavedTab extends StatelessWidget {
  final List<PinModel> pins;
  const _SavedTab({required this.pins});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (pins.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(l.noSavedPins, style: const TextStyle(color: _kText2, fontSize: 14)),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pins.length,
      itemBuilder: (context, index) {
        final pin = pins[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              pin.photoPath != null && !kIsWeb
                  ? Image.file(File(pin.photoPath!), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.primaryLight))
                  : Container(color: AppColors.primaryLight,
                      child: const Center(child: Icon(Icons.bookmark_outline, size: 28, color: AppColors.primary))),
              Positioned(
                bottom: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(pin.category,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
