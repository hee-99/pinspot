import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/community_service.dart';

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
  bool _submitting = false;

  static const _emojis = [
    '📍','🏔️','🌊','🌿','🏚️','📸','🌃','🗿','💧','🎨',
    '🍜','🎭','🏛️','🌸','🔦','🛤️','🏕️','🌋','🏖️','🎪',
  ];

  static const _colors = [
    0xFFFF7043, 0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0,
    0xFFFF9800, 0xFF00BCD4, 0xFFE91E63, 0xFF795548,
    0xFF3F51B5, 0xFF607D8B,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _submitting = true);

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
      createdAt: DateTime.now(),
    );

    await CommunityService.createCommunity(community);
    if (mounted) Navigator.pop(context, true);
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
            // Preview card
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(_selectedEmoji, style: const TextStyle(fontSize: 44)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Emoji picker
            const Text('아이콘', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((e) {
                final selected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
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
            const Text('색상', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: _colors.map((c) {
                final selected = c == _selectedColor;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
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
            const SizedBox(height: 36),

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
