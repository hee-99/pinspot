import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pin_model.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/utils/marker_builder.dart';

class _Pin {
  final LatLng pos;
  final String name;
  final String category;
  const _Pin(this.pos, this.name, this.category);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = Completer<GoogleMapController>();
  String? _mapStyle;
  LatLng? _currentPos;
  bool _locationLoading = true;
  String? _locationError;
  String _selectedCategory = '전체';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  List<String> _categories = [];
  bool _isNavigating = false;
  bool _navLoading = false;
  Set<Polyline> _polylines = {};
  DirectionsResult? _navInfo;
  String? _navDestName;
  List<PinModel> _savedPins = [];
  Map<String, BitmapDescriptor> _markerIcons = {};

  static const _defaultPos = LatLng(37.5665, 126.9780);

  static final _pins = [
    _Pin(const LatLng(37.5796, 126.9770), '경복궁 옆 골목', '문화재'),
    _Pin(const LatLng(37.5512, 126.9882), '서울 숨겨진 조각상', '조각상'),
    _Pin(const LatLng(37.6176, 127.0060), '북한산 뷰포인트', '등산'),
    _Pin(const LatLng(37.5443, 127.0557), '성수동 폐공장', '폐허'),
    _Pin(const LatLng(37.5798, 127.0018), '낙산공원 야경', '사진 명소'),
  ];

  Set<Marker> get _markers {
    var staticList = _selectedCategory == '전체'
        ? _pins
        : _pins.where((p) => p.category == _selectedCategory).toList();
    var savedList = _selectedCategory == '전체'
        ? _savedPins
        : _savedPins.where((p) => p.category == _selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      staticList = staticList.where((p) =>
        p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q),
      ).toList();
      savedList = savedList.where((p) =>
        p.title.toLowerCase().contains(q) || p.category.toLowerCase().contains(q),
      ).toList();
    }
    final staticMarkers = staticList.map((pin) => Marker(
      markerId: MarkerId('static_${pin.name}'),
      position: pin.pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(14.0),
      onTap: () => _showPinSheet(pin),
    )).toSet();
    final savedMarkers = savedList.map((pin) => Marker(
      markerId: MarkerId('saved_${pin.id}'),
      position: LatLng(pin.lat, pin.lng),
      icon: _markerIcons[pin.id] ?? BitmapDescriptor.defaultMarkerWithHue(14.0),
      onTap: () => _showSavedPinSheet(pin),
    )).toSet();
    return {...staticMarkers, ...savedMarkers};
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _fetchLocation();
    _loadCategories();
    _loadSavedPins();
    PinRefreshNotifier.instance.addListener(_loadSavedPins);
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _loadSavedPins() async {
    final pins = await PinService.getPins();
    if (!mounted) return;
    final Map<String, BitmapDescriptor> icons = {};
    for (final pin in pins) {
      if (pin.photoPath != null) {
        icons[pin.id] = await MarkerBuilder.buildPhotoMarker(pin.photoPath!);
      }
    }
    if (!mounted) return;
    setState(() {
      _savedPins = pins;
      _markerIcons = icons;
    });
  }

  @override
  void dispose() {
    PinRefreshNotifier.instance.removeListener(_loadSavedPins);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    if (!mounted) return;
    setState(() => _mapStyle = style);
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _locationError = '위치 서비스가 꺼져있습니다';
          _locationLoading = false;
        });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError = '위치 권한이 필요합니다';
          _locationLoading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _currentPos = LatLng(pos.latitude, pos.longitude);
        _locationLoading = false;
        _locationError = null;
      });
      final ctrl = await _mapCtrl.future;
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(_currentPos!, 14));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = '위치를 가져올 수 없습니다';
      });
    }
  }

  Future<void> _moveToMyLocation() async {
    if (_currentPos == null) {
      await _fetchLocation();
      return;
    }
    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(_currentPos!, 15));
  }

  void _showPinSheet(_Pin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PinBottomSheet(
        pin: pin,
        currentPos: _currentPos,
        onNavigate: () {
          Navigator.pop(context);
          _startNavigation(pin.pos, pin.name);
        },
        onShare: () {
          Navigator.pop(context);
          _sharePin(pin.pos, pin.name, pin.category);
        },
      ),
    );
  }

  void _showSavedPinSheet(PinModel pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SavedPinBottomSheet(
        pin: pin,
        currentPos: _currentPos,
        onNavigate: () {
          Navigator.pop(context);
          _startNavigation(LatLng(pin.lat, pin.lng), pin.title);
        },
        onShare: () {
          Navigator.pop(context);
          _sharePin(LatLng(pin.lat, pin.lng), pin.title, pin.category);
        },
      ),
    );
  }

  Future<void> _startNavigation(LatLng destination, String name) async {
    if (_currentPos == null) {
      _showSnack('현재 위치를 가져오는 중입니다...');
      await _fetchLocation();
      if (_currentPos == null) {
        _showSnack('현재 위치를 확인할 수 없습니다');
        return;
      }
    }
    setState(() {
      _navLoading = true;
      _navDestName = name;
      _isNavigating = false;
      _polylines = {};
    });

    final result = await DirectionsService.getDirections(
      origin: _currentPos!,
      destination: destination,
    );

    if (!mounted) return;
    if (result == null) {
      setState(() {
        _navLoading = false;
        _navDestName = null;
      });
      _showSnack('경로를 찾을 수 없습니다. 네트워크를 확인해주세요.');
      return;
    }

    setState(() {
      _navInfo = result;
      _isNavigating = true;
      _navLoading = false;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: result.polylinePoints,
          color: AppTheme.primary,
          width: 5,
        ),
      };
    });

    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFromPoints(result.polylinePoints), 80),
    );
  }

  void _cancelNavigation() {
    setState(() {
      _isNavigating = false;
      _navLoading = false;
      _polylines = {};
      _navInfo = null;
      _navDestName = null;
    });
  }

  void _sharePin(LatLng pos, String name, String category) {
    Share.share(
      '📍 $name ($category)\n'
      'https://maps.google.com/?q=${pos.latitude},${pos.longitude}',
      subject: name,
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _defaultPos, zoom: 13),
            onMapCreated: _mapCtrl.complete,
            style: _mapStyle,
            myLocationEnabled: _currentPos != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          // 상단 검색바
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: '장소, 카테고리 검색',
                  leading: const Icon(Icons.search, color: AppTheme.textSecondary),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                          ),
                        ]
                      : null,
                  backgroundColor: WidgetStateProperty.all(AppTheme.surface),
                  elevation: WidgetStateProperty.all(3),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
          ),
          // 카테고리 칩 (길찾기 중에는 숨김)
          if (!_isNavigating && !_navLoading)
            Positioned(
              bottom: 90, left: 16, right: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['전체', ..._categories].map((label) {
                    final sel = _selectedCategory == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          // 경로 탐색 중 로딩
          if (_navLoading)
            Positioned(
              bottom: 90, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    ),
                    SizedBox(width: 12),
                    Text('경로를 탐색하는 중...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          // 길찾기 정보 패널
          if (_isNavigating && _navInfo != null && _navDestName != null)
            Positioned(
              bottom: 90, left: 16, right: 16,
              child: _NavigationPanel(
                destination: _navDestName!,
                distance: _navInfo!.distance,
                duration: _navInfo!.duration,
                onCancel: _cancelNavigation,
              ),
            ),
          // 내 위치 버튼
          Positioned(
            bottom: (_isNavigating || _navLoading) ? 220 : 160,
            right: 16,
            child: GestureDetector(
              onTap: _moveToMyLocation,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _locationLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Icon(Icons.my_location, color: AppTheme.primary, size: 22),
              ),
            ),
          ),
          // 위치 에러 배너 (탭하면 재시도)
          if (_locationError != null && !_locationLoading)
            Positioned(
              top: 100, left: 16, right: 16,
              child: GestureDetector(
                onTap: _fetchLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('탭하여 재시도', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 핀 정보 바텀시트
// ──────────────────────────────────────────────
class _PinBottomSheet extends StatelessWidget {
  final _Pin pin;
  final LatLng? currentPos;
  final VoidCallback onNavigate;
  final VoidCallback onShare;

  const _PinBottomSheet({
    required this.pin,
    required this.currentPos,
    required this.onNavigate,
    required this.onShare,
  });

  String? get _distanceLabel {
    if (currentPos == null) return null;
    final m = Geolocator.distanceBetween(
      currentPos!.latitude, currentPos!.longitude,
      pin.pos.latitude, pin.pos.longitude,
    );
    return m >= 1000
        ? '${(m / 1000).toStringAsFixed(1)}km'
        : '${m.toStringAsFixed(0)}m';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceLabel;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pin.category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (dist != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.near_me, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text(dist, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: AppTheme.primary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions, size: 18, color: Colors.white),
                    label: const Text(
                      '길찾기',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_outlined, color: AppTheme.textPrimary, size: 20),
                    tooltip: '공유',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 길찾기 진행 중 패널
// ──────────────────────────────────────────────
class _NavigationPanel extends StatelessWidget {
  final String destination;
  final String distance;
  final String duration;
  final VoidCallback onCancel;

  const _NavigationPanel({
    required this.destination,
    required this.distance,
    required this.duration,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  destination,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text(distance, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Text(duration, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Color(0xFFC62828), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 저장된 핀 바텀시트
// ──────────────────────────────────────────────
class _SavedPinBottomSheet extends StatelessWidget {
  final PinModel pin;
  final LatLng? currentPos;
  final VoidCallback onNavigate;
  final VoidCallback onShare;

  const _SavedPinBottomSheet({
    required this.pin,
    required this.currentPos,
    required this.onNavigate,
    required this.onShare,
  });

  String? get _distanceLabel {
    if (currentPos == null) return null;
    final m = Geolocator.distanceBetween(
      currentPos!.latitude, currentPos!.longitude,
      pin.lat, pin.lng,
    );
    return m >= 1000 ? '${(m / 1000).toStringAsFixed(1)}km' : '${m.toStringAsFixed(0)}m';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceLabel;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pin.photoPath != null && !kIsWeb)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  File(pin.photoPath!),
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pin.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(pin.category,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                ),
                                if (dist != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.near_me, size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(dist, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppTheme.primary, size: 22),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(pin.description,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.directions, size: 18, color: Colors.white),
                          label: const Text('길찾기',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share_outlined, color: AppTheme.textPrimary, size: 20),
                          tooltip: '공유',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
