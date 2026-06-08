import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/landmark_info_model.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/landmark_info_service.dart';
import '../../../core/services/pin_service.dart';

enum _FailReason { none, gps, exif, distance }

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  static const double _maxDistance = 500.0;

  int _step = 0;
  PinModel? _savedPin;

  XFile? _pickedFile;
  bool _isVerifying = false;
  bool _locationValid = false;
  String _verifyMessage = '';
  double? _distanceMeters;
  _FailReason _failReason = _FailReason.none;

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
    final l = AppLocalizations.of(context);
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
      _verifyMessage = l.verifyingLocationMsg;
      _distanceMeters = null;
    });

    final currentPos = await _getCurrentPosition();
    if (currentPos == null) {
      setState(() {
        _isVerifying = false;
        _locationValid = false;
        _verifyMessage = l.noGpsMsg;
        _failReason = _FailReason.gps;
      });
      return;
    }

    if (fromCamera) {
      setState(() {
        _isVerifying = false;
        _locationValid = true;
        _verifyMessage = l.cameraVerifyMsg;
        _distanceMeters = 0;
        _pinLat = currentPos.latitude;
        _pinLng = currentPos.longitude;
        _failReason = _FailReason.none;
      });
      return;
    }

    final exifPos = await _extractExifLocation(file.path);
    if (exifPos == null) {
      setState(() {
        _isVerifying = false;
        _locationValid = false;
        _verifyMessage = l.noExifMsg;
        _failReason = _FailReason.exif;
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
      _failReason = valid ? _FailReason.none : _FailReason.distance;
      if (valid) {
        _pinLat = exifPos.lat;
        _pinLng = exifPos.lng;
      }
      _verifyMessage = valid
          ? l.verifySuccessMsg
          : l.verifyFailMsg(dist.toStringAsFixed(0));
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

    if (mounted) setState(() { _isSubmitting = false; _savedPin = pin; _step = 3; });
  }

  Future<void> _shareToCommunities(List<String> communityIds) async {
    if (_savedPin != null) {
      for (final id in communityIds) {
        await CommunityService.addCommunityPin(id, _savedPin!);
      }
    }
    if (mounted) setState(() => _step = 4);
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3EE),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.createSteps[_step],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1C1C1E)),
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
              failReason: _failReason,
              onRetry: () => setState(() => _step = 0),
              onContinue: _locationValid ? () => setState(() => _step = 2) : null,
              onOpenSettings: () => Geolocator.openLocationSettings(),
            ),
            _InputStep(
              file: _pickedFile,
              categories: _categories,
              categoriesLoaded: _categoriesLoaded,
              selectedCategory: _selectedCategory,
              titleCtrl: _titleCtrl,
              descCtrl: _descCtrl,
              isSubmitting: _isSubmitting,
              lat: _pinLat,
              lng: _pinLng,
              onCategorySelect: (c) => setState(() => _selectedCategory = c),
              onAddCategory: _addNewCategory,
              onSubmit: _submit,
            ),
            _ShareStep(
              pin: _savedPin,
              onShare: _shareToCommunities,
              onSkip: () => setState(() => _step = 4),
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l.photoSourceQ,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(l.photoSourceDesc,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 40),
          _SourceCard(
            icon: Icons.camera_alt,
            title: l.camera,
            subtitle: l.cameraSubtitle,
            badge: l.recommended,
            onTap: () => onPick(true),
          ),
          const SizedBox(height: 16),
          _SourceCard(
            icon: Icons.photo_library_outlined,
            title: l.gallery,
            subtitle: l.gallerySubtitle,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.location500mInfo,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE65100), height: 1.5),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 3))],
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
  final _FailReason failReason;
  final VoidCallback onRetry;
  final VoidCallback? onContinue;
  final VoidCallback onOpenSettings;

  const _VerifyStep({
    required this.file,
    required this.isVerifying,
    required this.isValid,
    required this.message,
    required this.distance,
    required this.failReason,
    required this.onRetry,
    required this.onContinue,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  Text(l.verifyingLocationMsg,
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                ] else ...[
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: isValid ? const Color(0xFFF0FDF4) : const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isValid
                          ? Icons.check_circle
                          : (failReason == _FailReason.gps
                              ? Icons.location_off_rounded
                              : failReason == _FailReason.exif
                                  ? Icons.image_not_supported_rounded
                                  : Icons.place_rounded),
                      color: isValid ? const Color(0xFF14532D) : const Color(0xFFC62828),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isValid ? l.locationSuccess : l.locationFail,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isValid ? const Color(0xFF14532D) : const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                  if (!isValid) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFDDB3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              failReason == _FailReason.gps
                                  ? l.gpsFailDetail
                                  : failReason == _FailReason.exif
                                      ? l.noExifDetail
                                      : l.distanceFailDetail,
                              style: const TextStyle(fontSize: 13, color: Color(0xFFE65100), height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (distance != null && distance! > 0) ...[
                    const SizedBox(height: 12),
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
                            l.distanceToLocation(distance!.toStringAsFixed(0)),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onContinue != null)
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  // 실패 케이스별 맞춤 액션 버튼
                  if (!isValid && !isVerifying) ...[
                    if (failReason == _FailReason.gps) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton.icon(
                          onPressed: onOpenSettings,
                          icon: const Icon(Icons.settings_rounded, size: 18, color: Colors.white),
                          label: Text(l.openLocationSettings,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                    if (failReason == _FailReason.exif) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // onRetry가 step 0으로 돌아가므로 카메라 탭을 유도
                            onRetry();
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                          label: Text(l.useCameraInstead,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                    if (failReason == _FailReason.distance) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.place_rounded, size: 18, color: Colors.white),
                          label: Text(l.goToLocation,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: onRetry,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.retry, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
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
  final double? lat;
  final double? lng;
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
    this.lat,
    this.lng,
    required this.onCategorySelect,
    required this.onAddCategory,
    required this.onSubmit,
  });

  @override
  State<_InputStep> createState() => _InputStepState();
}

class _InputStepState extends State<_InputStep> {
  LandmarkInfo? _aiInfo;
  bool _isLoadingAi = false;

  Future<void> _fetchAiInfo() async {
    final l = AppLocalizations.of(context);
    final title = widget.titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.aiEnterNameFirst),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() { _isLoadingAi = true; _aiInfo = null; });
    final info = await LandmarkInfoService.fetchInfo(
      placeName: title,
      lat: widget.lat,
      lng: widget.lng,
    );
    if (mounted) setState(() { _isLoadingAi = false; _aiInfo = info; });
  }

  void _useAiDescription() {
    if (_aiInfo == null) return;
    widget.descCtrl.text = _aiInfo!.suggestedDescription;
  }

  void _showAddCategoryDialog() {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.createCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.categoryNameHint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: const Color(0xFFEEECE7),
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
            child: Text(l.cancel, style: const TextStyle(color: AppTheme.textSecondary)),
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
            child: Text(l.add, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
              Text(l.category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: _showAddCategoryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Text(l.newCategory, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
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
                      color: isSelected ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? null : const [BoxShadow(color: Color(0x09000000), blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Text(l.placeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.titleCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: l.placeNameHint,
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: const Color(0xFFEEECE7),
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
          const SizedBox(height: 8),
          _AiInfoSection(
            isLoading: _isLoadingAi,
            info: _aiInfo,
            onFetch: _fetchAiInfo,
            onUseDescription: _useAiDescription,
          ),
          const SizedBox(height: 20),
          Text(l.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.descCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: l.descriptionHint,
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: const Color(0xFFEEECE7),
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
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l.submitPin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── AI 장소 정보 섹션 ────────────────────────────────────────────────────────

class _AiInfoSection extends StatelessWidget {
  final bool isLoading;
  final LandmarkInfo? info;
  final VoidCallback onFetch;
  final VoidCallback onUseDescription;

  const _AiInfoSection({
    required this.isLoading,
    required this.info,
    required this.onFetch,
    required this.onUseDescription,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isLoading ? null : onFetch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLoading
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                else
                  const Icon(Icons.auto_awesome, size: 15, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  isLoading ? l.aiFetching : l.aiFetchLocation,
                  style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        if (info != null) ...[
          const SizedBox(height: 12),
          _LandmarkInfoCard(info: info!, onUseDescription: onUseDescription),
        ],
      ],
    );
  }
}

class _LandmarkInfoCard extends StatelessWidget {
  final LandmarkInfo info;
  final VoidCallback onUseDescription;

  const _LandmarkInfoCard({required this.info, required this.onUseDescription});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4EDDC)),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(l.aiInfo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text(info.sourceLabel,
                      style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icon: Icons.history_edu_outlined, label: l.originHistory, text: info.origin),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.place_outlined, label: l.highlights, text: info.highlights),
                if (info.bestTime != null && info.bestTime!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: l.bestTime, text: info.bestTime!),
                ],
                if (info.tip != null && info.tip!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.tips_and_updates_outlined, label: l.visitTip, text: info.tip!),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onUseDescription,
                    icon: const Icon(Icons.edit_note, size: 16, color: Colors.white),
                    label: Text(l.useAiDescription,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _InfoRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 커뮤니티 공유 단계 ──────────────────────────────────────────────────────────

class _ShareStep extends StatefulWidget {
  final PinModel? pin;
  final Future<void> Function(List<String> communityIds) onShare;
  final VoidCallback onSkip;

  const _ShareStep({required this.pin, required this.onShare, required this.onSkip});

  @override
  State<_ShareStep> createState() => _ShareStepState();
}

class _ShareStepState extends State<_ShareStep> {
  List<CommunityModel> _communities = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await CommunityService.getCommunities();
    if (mounted) setState(() { _communities = all.where((c) => c.isJoined).toList(); _loading = false; });
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    await widget.onShare(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.shareToCommunityQ,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(l.shareSubtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          if (_communities.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8)]),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 44, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(l.noCommunity,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _communities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = _communities[i];
                  final isSelected = _selected.contains(c.id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) { _selected.remove(c.id); }
                      else { _selected.add(c.id); }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? c.color.withValues(alpha: 0.07) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? c.color : const Color(0xFFEEECE7),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: c.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text(c.description,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? c.color : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? c.color : const Color(0xFFCCCCCC), width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_sharing || _selected.isEmpty) ? null : _share,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _sharing
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _selected.isEmpty ? l.selectCommunity : l.shareNCommunities(_selected.length),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 52,
            child: TextButton(
              onPressed: _sharing ? null : widget.onSkip,
              child: Text(l.skip, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 완료 화면 ────────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  final VoidCallback onClose;
  const _DoneStep({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Text(l.pinRegistered, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(l.pinRegisteredDesc, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l.done, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
