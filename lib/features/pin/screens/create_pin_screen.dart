import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/pin_service.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  static const double _maxDistance = 500.0;

  int _step = 0; // 0: source, 1: verify, 2: input, 3: done

  XFile? _pickedFile;
  bool _isVerifying = false;
  bool _locationValid = false;
  String _verifyMessage = '';
  double? _distanceMeters;

  String _selectedCategory = '';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;
  List<String> _categories = [];
  bool _categoriesLoaded = false;
  double? _pinLat;
  double? _pinLng;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    if (mounted) setState(() { _categories = cats; _categoriesLoaded = true; });
  }

  Future<void> _addNewCategory(String name) async {
    await CategoryService.addCategory(name);
    await _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<({double lat, double lng})?> _extractExifLocation(String path) async {
    if (kIsWeb) return null;
    final bytes = await File(path).readAsBytes();
    final tags = await readExifFromBytes(bytes);
    if (tags.isEmpty) return null;

    final latTag = tags['GPS GPSLatitude'];
    final latRef = tags['GPS GPSLatitudeRef'];
    final lngTag = tags['GPS GPSLongitude'];
    final lngRef = tags['GPS GPSLongitudeRef'];
    if (latTag == null || lngTag == null) return null;

    double dmsToDecimal(IfdTag tag) {
      final parts = tag.values.toList();
      if (parts.length < 3) return 0;
      final d = (parts[0] as Ratio).toDouble();
      final m = (parts[1] as Ratio).toDouble();
      final s = (parts[2] as Ratio).toDouble();
      return d + m / 60 + s / 3600;
    }

    double lat = dmsToDecimal(latTag);
    double lng = dmsToDecimal(lngTag);
    if (latRef?.printable == 'S') lat = -lat;
    if (lngRef?.printable == 'W') lng = -lng;

    return (lat: lat, lng: lng);
  }

  Future<void> _pickAndVerify(bool fromCamera) async {
    final picker = ImagePicker();
    final XFile? file = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 85)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _pickedFile = file;
      _step = 1;
      _isVerifying = true;
      _locationValid = false;
      _verifyMessage = '위치를 확인하는 중...';
      _distanceMeters = null;
    });

    final currentPos = await _getCurrentPosition();
    if (currentPos == null) {
      setState(() {
        _isVerifying = false;
        _locationValid = false;
        _verifyMessage = '현재 위치를 가져올 수 없습니다.\nGPS 권한을 확인해주세요.';
      });
      return;
    }

    if (fromCamera) {
      setState(() {
        _isVerifying = false;
        _locationValid = true;
        _verifyMessage = '카메라로 촬영한 사진은 현재 위치에서\n찍힌 것으로 자동 인증됩니다.';
        _distanceMeters = 0;
        _pinLat = currentPos.latitude;
        _pinLng = currentPos.longitude;
      });
      return;
    }

    final exifPos = await _extractExifLocation(file.path);
    if (exifPos == null) {
      setState(() {
        _isVerifying = false;
        _locationValid = false;
        _verifyMessage = 'EXIF 위치 정보가 없는 사진입니다.\n위치 정보가 포함된 사진을 선택해주세요.';
      });
      return;
    }

    final dist = Geolocator.distanceBetween(
      exifPos.lat, exifPos.lng,
      currentPos.latitude, currentPos.longitude,
    );

    final valid = dist <= _maxDistance;
    setState(() {
      _isVerifying = false;
      _distanceMeters = dist;
      _locationValid = valid;
      if (valid) {
        _pinLat = exifPos.lat;
        _pinLng = exifPos.lng;
      }
      _verifyMessage = valid
          ? '위치 인증 성공!\n사진 촬영 장소와 현재 위치가 일치합니다.'
          : '위치 불일치로 업로드가 제한됩니다.\n사진 촬영 장소(${dist.toStringAsFixed(0)}m 떨어짐)에서만 핀을 등록할 수 있습니다.';
    });
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || _selectedCategory.isEmpty) return;
    if (_pinLat == null || _pinLng == null) return;
    if (title.length > 50 || desc.length > 500) return;
    if (!_isValidLatLng(_pinLat!, _pinLng!)) return;

    setState(() => _isSubmitting = true);

    final pin = PinModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: _selectedCategory,
      description: desc,
      lat: _pinLat!,
      lng: _pinLng!,
      photoPath: kIsWeb ? null : _pickedFile?.path,
      createdAt: DateTime.now(),
    );

    await PinService.savePin(pin);
    PinRefreshNotifier.instance.notifyPinAdded();

    if (mounted) setState(() { _isSubmitting = false; _step = 3; });
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          ['사진 선택', '위치 확인', '핀 정보 입력', '등록 완료'][_step],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: [
            _SourceStep(onPick: _pickAndVerify),
            _VerifyStep(
              file: _pickedFile,
              isVerifying: _isVerifying,
              isValid: _locationValid,
              message: _verifyMessage,
              distance: _distanceMeters,
              onRetry: () => setState(() => _step = 0),
              onContinue: _locationValid ? () => setState(() => _step = 2) : null,
            ),
            _InputStep(
              file: _pickedFile,
              categories: _categories,
              categoriesLoaded: _categoriesLoaded,
              selectedCategory: _selectedCategory,
              titleCtrl: _titleCtrl,
              descCtrl: _descCtrl,
              isSubmitting: _isSubmitting,
              onCategorySelect: (c) => setState(() => _selectedCategory = c),
              onAddCategory: _addNewCategory,
              onSubmit: _submit,
            ),
            _DoneStep(onClose: () => Navigator.of(context).pop()),
          ][_step],
        ),
      ),
    );
  }
}

class _SourceStep extends StatelessWidget {
  final Future<void> Function(bool fromCamera) onPick;
  const _SourceStep({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('사진을 어떻게 추가할까요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('카메라로 직접 찍거나 갤러리에서 선택하세요.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          _SourceCard(
            icon: Icons.camera_alt,
            title: '카메라로 촬영',
            subtitle: '지금 이 위치에서 바로 찍기',
            badge: '추천',
            onTap: () => onPick(true),
          ),
          const SizedBox(height: 16),
          _SourceCard(
            icon: Icons.photo_library_outlined,
            title: '갤러리에서 선택',
            subtitle: 'GPS 정보가 포함된 사진만 등록 가능',
            badge: null,
            onTap: () => onPick(false),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '갤러리 사진의 촬영 장소와 현재 위치가 500m 이내여야 핀 등록이 가능합니다.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFE65100), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _VerifyStep extends StatelessWidget {
  final XFile? file;
  final bool isVerifying;
  final bool isValid;
  final String message;
  final double? distance;
  final VoidCallback onRetry;
  final VoidCallback? onContinue;

  const _VerifyStep({
    required this.file,
    required this.isVerifying,
    required this.isValid,
    required this.message,
    required this.distance,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (file != null)
          SizedBox(
            height: 240,
            width: double.infinity,
            child: kIsWeb
                ? Image.network(file!.path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())
                : Image.file(File(file!.path), fit: BoxFit.cover),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (isVerifying) ...[
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 20),
                  const Text('위치를 확인하는 중...', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                ] else ...[
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isValid ? Icons.check_circle : Icons.cancel,
                      color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isValid ? '위치 인증 성공' : '위치 불일치',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                  if (distance != null && distance! > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.social_distance, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            '촬영 장소까지 ${distance!.toStringAsFixed(0)}m',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onContinue != null)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('다음 단계로', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onRetry,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('다시 선택', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InputStep extends StatefulWidget {
  final XFile? file;
  final List<String> categories;
  final bool categoriesLoaded;
  final String selectedCategory;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final bool isSubmitting;
  final ValueChanged<String> onCategorySelect;
  final Future<void> Function(String) onAddCategory;
  final VoidCallback onSubmit;

  const _InputStep({
    required this.file,
    required this.categories,
    required this.categoriesLoaded,
    required this.selectedCategory,
    required this.titleCtrl,
    required this.descCtrl,
    required this.isSubmitting,
    required this.onCategorySelect,
    required this.onAddCategory,
    required this.onSubmit,
  });

  @override
  State<_InputStep> createState() => _InputStepState();
}

class _InputStepState extends State<_InputStep> {
  void _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('카테고리 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '카테고리 이름 입력',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onSubmitted: (v) async {
            if (v.trim().isNotEmpty) {
              Navigator.pop(ctx);
              await widget.onAddCategory(v.trim());
              widget.onCategorySelect(v.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                Navigator.pop(ctx);
                await widget.onAddCategory(v);
                widget.onCategorySelect(v);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(widget.file!.path, height: 180, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink())
                  : Image.file(File(widget.file!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('카테고리', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: _showAddCategoryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppTheme.primary),
                      SizedBox(width: 3),
                      Text('새 카테고리', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!widget.categoriesLoaded)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((label) {
                final isSelected = widget.selectedCategory == label;
                return GestureDetector(
                  onTap: () => widget.onCategorySelect(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF444444),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const Text('장소 이름', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.titleCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: '예: 북한산 백운대 정상',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          const Text('설명', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.descCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: '이 장소에 대해 자유롭게 설명해주세요.',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('핀 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  final VoidCallback onClose;
  const _DoneStep({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppTheme.primary, size: 52),
          ),
          const SizedBox(height: 28),
          const Text('핀이 등록됐어요!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text(
            '지도에서 내 핀을 확인할 수 있어요.',
            style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
