import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
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

class _DangerZone {
  final LatLng pos;
  final String name;
  final String reason;
  final String icon;
  const _DangerZone(this.pos, this.name, this.reason, this.icon);
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

  static const _dangerZones = [
    _DangerZone(LatLng(37.0742, 127.0844), '살목지 계곡', '급류·익수 위험 구간. 우기 시 접근 금지.', '🌊'),
    _DangerZone(LatLng(37.7455, 128.8677), '한탄강 급류 구간', '수심 급변·암초 다수. 사망 사고 발생지.', '⚡'),
    _DangerZone(LatLng(37.6568, 126.9980), '북한산 인수봉', '낙석·추락 위험. 우천 시 출입 통제.', '🪨'),
    _DangerZone(LatLng(38.1197, 128.4661), '설악산 공룡능선', '강풍·낙석 위험. 비인가 루트 접근 금지.', '⛰️'),
    _DangerZone(LatLng(35.3349, 127.7305), '지리산 천왕봉 북능', '겨울 결빙·폭풍 위험 구간.', '🧊'),
    _DangerZone(LatLng(36.5685, 128.7289), '주왕산 급경사 폭포', '미끄럼·낙하 위험. 우기 접근 금지.', '💧'),
    _DangerZone(LatLng(35.1796, 129.0756), '부산 해운대 이안류', '이안류 발생 구간. 해수욕 금지 구역.', '🌊'),
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
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () => _showPinSheet(pin),
    )).toSet();
    final savedMarkers = savedList.map((pin) {
      final isDanger = pin.category.contains('위험');
      return Marker(
        markerId: MarkerId('saved_${pin.id}'),
        position: LatLng(pin.lat, pin.lng),
        icon: isDanger
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : (_markerIcons[pin.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
        onTap: () => _showSavedPinSheet(pin),
      );
    }).toSet();

    // 위험 지역 마커 (카테고리 필터 무시, 항상 표시)
    final dangerMarkers = _dangerZones.map((dz) => Marker(
      markerId: MarkerId('danger_${dz.name}'),
      position: dz.pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: () => _showDangerSheet(dz),
    )).toSet();

    return {...staticMarkers, ...savedMarkers, ...dangerMarkers};
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

  void _showDangerSheet(_DangerZone dz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DangerBottomSheet(dangerZone: dz),
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
          color: AppColors.primary,
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
        backgroundColor: AppColors.neutral900,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 15, color: AppColors.neutral900),
                    decoration: InputDecoration(
                      hintText: '장소, 카테고리 검색',
                      hintStyle: const TextStyle(color: AppColors.neutral400, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral400, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                              child: const Icon(Icons.close_rounded, color: AppColors.neutral400, size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                      filled: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 카테고리 칩 (길찾기 중에는 숨김)
          if (!_isNavigating && !_navLoading)
            Positioned(
              bottom: 90, left: 0, right: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['전체', ..._categories].map((label) {
                    final sel = _selectedCategory == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: sel
                                    ? AppColors.primary.withValues(alpha: 0.30)
                                    : Colors.black.withValues(alpha: 0.10),
                                blurRadius: sel ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                              color: sel ? Colors.white : AppColors.neutral600,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text('경로를 탐색하는 중...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
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
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: _locationLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
              ),
            ),
          ),
          // 위치 에러 배너 (탭하면 재시도)
          if (_locationError != null && !_locationLoading)
            Positioned(
              top: 80, left: 16, right: 16,
              child: GestureDetector(
                onTap: _fetchLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.neutral900.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_rounded, color: Colors.white, size: 15),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_locationError!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Text('재시도', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pin.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(pin.category,
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                                if (dist != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.near_me_rounded, size: 12, color: AppColors.neutral400),
                                  const SizedBox(width: 3),
                                  Text(dist, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.directions_walk_rounded, size: 18, color: Colors.white),
                          label: const Text('길찾기',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: IconButton(
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryMuted],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _NavStat(Icons.straighten_rounded, distance, AppColors.primary),
                          const SizedBox(width: 12),
                          _NavStat(Icons.access_time_rounded, duration, const Color(0xFF5C6BC0)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: AppColors.neutral500, size: 18),
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

class _NavStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _NavStat(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 11, color: color),
        ),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ],
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pin.photoPath != null && !kIsWeb)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.file(
                  File(pin.photoPath!),
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pin.title,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(pin.category,
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                                if (dist != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.near_me_rounded, size: 12, color: AppColors.neutral400),
                                  const SizedBox(width: 3),
                                  Text(dist, style: const TextStyle(fontSize: 12, color: AppColors.neutral400)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (pin.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(pin.description,
                        style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.55),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.directions_walk_rounded, size: 18, color: Colors.white),
                          label: const Text('길찾기',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: IconButton(
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share_outlined, color: AppColors.neutral900, size: 20),
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

// ──────────────────────────────────────────────
// 위험 지역 바텀시트
// ──────────────────────────────────────────────
class _DangerBottomSheet extends StatelessWidget {
  final _DangerZone dangerZone;
  const _DangerBottomSheet({required this.dangerZone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(dangerZone.icon, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(6)),
                          child: const Text('⚠️ 위험 지역',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 5),
                        Text(dangerZone.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(dangerZone.reason,
                            style: const TextStyle(fontSize: 13, color: Color(0xFFB71C1C), height: 1.55)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('확인했습니다', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
