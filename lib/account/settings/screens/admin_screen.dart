import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinspot/design/theme/app_theme.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/account/auth/services/auth_service.dart';
import 'package:pinspot/account/auth/services/sample_data_service.dart';
import 'package:pinspot/core/models/user_model.dart';
import 'package:pinspot/features/pin/services/pin_service.dart';

// 관리자 화면 — 설정의 숨겨진 제스처(닉네임 7번 탭)로 관리자 모드가 켜진 계정만 진입 가능.
// 서버가 없는 로컬 전용 앱이라 "관리자"는 이 기기의 로컬 데이터(샘플 핀 등)를 관리하는 개념이며,
// 다른 유저의 핀/계정을 관리하는 기능은 백엔드 연동 전까지는 제공되지 않는다.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  UserModel? _user;
  int _sampleCount = 0;
  int _otherCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.getUser();
    final count = await SampleDataService.sampleCount();
    final allPins = await PinService.getPins();
    final otherCount = allPins.where((p) => !p.id.startsWith('sample_')).length;
    if (mounted) {
      setState(() { _user = user; _sampleCount = count; _otherCount = otherCount; _loading = false; });
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _reseedSamplePins() async {
    await SampleDataService.seedManually();
    PinRefreshNotifier.instance.notifyPinAdded();
    await _load();
    if (mounted) _snack('샘플 핀을 다시 채웠어요');
  }

  Future<void> _clearSamplePins() async {
    final removed = await SampleDataService.clearSamplePins();
    PinRefreshNotifier.instance.notifyPinAdded();
    await _load();
    if (mounted) _snack('샘플 핀 $removed개를 삭제했어요');
  }

  Future<void> _clearOtherPins() async {
    final allPins = await PinService.getPins();
    final others = allPins.where((p) => !p.id.startsWith('sample_')).toList();
    for (final p in others) {
      await PinService.deletePin(p.id);
    }
    PinRefreshNotifier.instance.notifyPinAdded();
    await _load();
    if (mounted) _snack('샘플 외 핀 ${others.length}개를 삭제했어요');
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    if (mounted) _snack('온보딩 플래그를 초기화했어요 (다음 앱 시작 시 온보딩부터 다시 나와요)');
  }

  Future<void> _turnOffAdminMode() async {
    final updated = await AuthService.toggleAdminMode();
    if (!mounted) return;
    if (updated != null) {
      Navigator.pop(context);
      _snack('관리자 모드를 껐어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('관리자', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                    title: Text(_user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_user?.email ?? _user?.provider ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('샘플 핀 데이터 관리'),
                _SectionCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        title: const Text('현재 샘플 핀 개수', style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text('$_sampleCount개',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _ActionTile(
                        icon: Icons.refresh_rounded,
                        label: '샘플 핀 다시 채우기',
                        onTap: _reseedSamplePins,
                      ),
                      _ActionTile(
                        icon: Icons.delete_outline_rounded,
                        label: '샘플 핀 전체 삭제',
                        color: const Color(0xFFC62828),
                        onTap: _clearSamplePins,
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.pin_drop_outlined, color: AppColors.primary),
                        title: const Text('샘플 외(테스트로 생성된) 핀 개수', style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text('$_otherCount개',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      _ActionTile(
                        icon: Icons.cleaning_services_outlined,
                        label: '샘플 외 핀 전체 삭제',
                        color: const Color(0xFFC62828),
                        onTap: _clearOtherPins,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('로컬 데이터 초기화'),
                _SectionCard(
                  child: _ActionTile(
                    icon: Icons.restart_alt_rounded,
                    label: '온보딩 플래그 초기화',
                    onTap: _resetOnboarding,
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('안내'),
                _SectionCard(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Pinspot은 서버 없이 이 기기의 로컬 저장소만 사용해요. 그래서 다른 유저의 핀이나 계정을 '
                      '관리하는 기능은 아직 지원되지 않아요. 백엔드가 붙으면 이 화면에 추가될 예정이에요.',
                      style: TextStyle(fontSize: 12, color: AppColors.neutral500, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  child: _ActionTile(
                    icon: Icons.toggle_off_outlined,
                    label: '관리자 모드 끄기',
                    color: const Color(0xFFC62828),
                    onTap: _turnOffAdminMode,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
    );
  }
}

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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color ?? AppColors.neutral600),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }
}
