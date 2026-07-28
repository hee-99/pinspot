import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/community_model.dart';
import '../../../core/models/pinpler_tier.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/pin_service.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedEmoji = '📍';
  int _selectedColor = 0xFFFF7043;
  bool _isPrivate = false;
  bool _submitting = false;
  String? _customImagePath;

  static const _emojis = [
    '📍','🏔️','🌊','🌿','🏚️','📸','🌃','🗿','💧','🎨',
    '🍜','🎭','🏛️','🌸','🔦','🛤️','🏕️','🌋','🏖️','🎪',
    '🌆','🐾','🎸','⛺','🦋','🍁','🏄','🎯','🌈','🔥',
  ];

  static const _colors = [
    0xFFFF7043, 0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0,
    0xFFFF9800, 0xFF00BCD4, 0xFFE91E63, 0xFF795548,
    0xFF3F51B5, 0xFF607D8B, 0xFFEC407A, 0xFF26A69A,
    0xFF42A5F5, 0xFF66BB6A, 0xFFAB47BC, 0xFFEF5350,
    0xFF29B6F6, 0xFF8D6E63, 0xFF5C6BC0, 0xFF26C6DA,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (file != null && mounted) setState(() => _customImagePath = file.path);
  }

  void _showCustomEmojiDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('이모티콘 직접 입력', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLength: 2,
          style: const TextStyle(fontSize: 36),
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '😊',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(_selectedColor), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final emoji = ctrl.text.trim();
              if (emoji.isNotEmpty) {
                setState(() { _selectedEmoji = emoji; _customImagePath = null; });
              }
              Navigator.pop(ctx);
            },
            child: const Text('선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCustomColorDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('커스텀 색상', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLength: 7,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '#FF7043',
            labelText: 'HEX 색상코드',
            prefixText: '#',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(_selectedColor), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final hex = ctrl.text.trim().replaceAll('#', '');
              if (hex.length == 6) {
                try {
                  setState(() => _selectedColor = 0xFF000000 | int.parse(hex, radix: 16));
                  Navigator.pop(ctx);
                } catch (_) {}
              }
            },
            child: const Text('적용', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) return;

    final pins = await PinService.getPins();
    final tier = PinplerTierX.fromPinCount(pins.length);
    final owned = (await CommunityService.getCommunities()).where((c) => c.isOwner).length;
    if (owned >= tier.communityCreateLimit) {
      if (!mounted) return;
      await _showLimitDialog(tier);
      return;
    }

    setState(() => _submitting = true);

    final code = _isPrivate ? CommunityService.generateJoinCode() : null;
    final community = CommunityModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: desc,
      emoji: _selectedEmoji,
      colorValue: _selectedColor,
      memberCount: 1,
      pinCount: 0,
      isOwner: true,
      isJoined: true,
      isPrivate: _isPrivate,
      joinCode: code,
      createdAt: DateTime.now(),
      imagePath: _customImagePath,
    );

    await CommunityService.createCommunity(community);

    if (!mounted) return;
    if (code != null) {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _CodeDialog(code: code, communityName: name, color: Color(_selectedColor)),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _showLimitDialog(PinplerTier tier) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tier.badgeEmoji),
            const SizedBox(width: 6),
            Flexible(child: Text('${tier.label} 등급 한도', style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
        content: Text(
          tier.nextThreshold == -1
              ? '현재 등급에서 만들 수 있는 커뮤니티 개수(최대 ${tier.communityCreateLimit}개)를 모두 사용했어요.'
              : '지금 등급(${tier.label})에서는 커뮤니티를 최대 ${tier.communityCreateLimit}개까지 만들 수 있어요.\n'
                '핀을 ${tier.nextThreshold}개까지 등록하면 다음 등급으로 올라가면서 더 많이 만들 수 있어요!',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: tier.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_selectedColor);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('커뮤니티 만들기',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card (tap to upload image)
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _customImagePath != null && !kIsWeb
                          ? Image.file(File(_customImagePath!), fit: BoxFit.cover,
                              width: 100, height: 100,
                              errorBuilder: (_, __, ___) =>
                                  Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 44))))
                          : Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 44))),
                    ),
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_customImagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _customImagePath = null),
                    child: Text('이미지 제거', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            const SizedBox(height: 28),

            // Emoji picker
            Row(
              children: [
                const Text('아이콘', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: _showCustomEmojiDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text('직접 입력', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((e) {
                final selected = e == _selectedEmoji && _customImagePath == null;
                return GestureDetector(
                  onTap: () => setState(() { _selectedEmoji = e; _customImagePath = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.15) : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFEEEEEE),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Color picker
            Row(
              children: [
                const Text('색상', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: _showCustomColorDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.colorize_outlined, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text('HEX 입력', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((c) {
                final selected = c == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Name
            const Text('커뮤니티 이름', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '예: 서울 숨은 골목 탐험대',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text('소개', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: '어떤 핀을 공유하는 커뮤니티인지 소개해주세요.',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 28),

            // 공개/비공개 토글
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _VisibilityOption(
                    icon: Icons.public,
                    title: '공개',
                    subtitle: '누구나 검색하고 참여할 수 있어요',
                    selected: !_isPrivate,
                    color: Color(_selectedColor),
                    onTap: () => setState(() => _isPrivate = false),
                  ),
                  const Divider(height: 1, indent: 56),
                  _VisibilityOption(
                    icon: Icons.lock_outline,
                    title: '비공개',
                    subtitle: '초대 코드가 있는 사람만 참여 가능해요',
                    selected: _isPrivate,
                    color: Color(_selectedColor),
                    onTap: () => setState(() => _isPrivate = true),
                  ),
                ],
              ),
            ),
            if (_isPrivate)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Color(_selectedColor)),
                    const SizedBox(width: 6),
                    Text(
                      '커뮤니티 생성 후 6자리 코드가 발급됩니다.',
                      style: TextStyle(fontSize: 12, color: Color(_selectedColor)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_submitting || _nameCtrl.text.trim().isEmpty)
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('커뮤니티 만들기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? color : AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeDialog extends StatelessWidget {
  final String code;
  final String communityName;
  final Color color;
  const _CodeDialog({required this.code, required this.communityName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.lock_open, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('초대 코드 발급 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('$communityName 멤버에게 공유하세요',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('코드가 복사됐어요'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: color,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, color: color, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('클립보드에 자동 복사됐어요',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('확인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
