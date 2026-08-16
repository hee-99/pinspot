import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pinspot/design/theme/app_colors.dart';
import 'package:pinspot/core/models/pin_model.dart';
import 'package:pinspot/core/models/pin_rating_schema.dart';
import 'package:pinspot/features/map/services/directions_service.dart';
import 'package:pinspot/core/services/category_service.dart';
import 'package:pinspot/features/pin/services/pin_service.dart';
import 'package:pinspot/design/utils/marker_builder.dart';
import 'package:pinspot/features/tigo/models/tigo_model.dart';
import 'package:pinspot/features/tigo/services/tigo_service.dart';
import 'package:pinspot/features/map/data/followed_pinplers.dart';
import 'package:pinspot/features/pin/screens/create_pin_screen.dart';
import 'package:pinspot/account/settings/screens/notification_settings_screen.dart';

// 지도 화면 — Google Maps 표시, GPS 현위치 추적, 저장된 핀 마커, 카테고리 필터, 경로 안내를 담당
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
  TravelStats? _travelStats;
  BitmapDescriptor? _myLocationIcon;
  StreamSubscription<Position>? _posSub;

  // "팔로우한 사람 지도 보기" — 토글 on/off 및 현재 선택된 핀플러 (null = 나)
  bool _showFollowed = false;
  int? _selectedFollowedIndex;

  static const _defaultPos = LatLng(37.5665, 126.9780);

  // 카테고리명에 따라 마커 색상(hue) 결정
  double _categoryHue(String category) {
    if (category.contains('위험')) return BitmapDescriptor.hueRed;
    if (category.contains('맛집')) return 30.0;
    if (category.contains('캠핑')) return BitmapDescriptor.hueCyan;
    if (category.contains('사진')) return BitmapDescriptor.hueAzure;
    if (category.contains('폐허') || category.contains('어반')) return BitmapDescriptor.hueViolet;
    if (category.contains('관광') || category.contains('조각')) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueGreen;
  }

  // 카테고리/검색어로 필터링된 사용자 저장 핀 목록 (팔로우한 다른 핀플러의 지도를 보는 중이면 내 핀은 숨김)
  List<PinModel> get _filteredSavedPins {
    if (_selectedFollowedIndex != null) return [];
    var list = _selectedCategory == '전체'
        ? _savedPins
        : _savedPins.where((p) => p.category == _selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
        p.title.toLowerCase().contains(q) || p.category.toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  int get _visiblePinCount => _filteredSavedPins.length;

  // 지도 마커 빌드 — 저장된 핀 + 내 위치 마커를 합쳐 반환
  Set<Marker> get _markers {
    final savedList = _filteredSavedPins;

    final savedMarkers = savedList.map((pin) {
      return Marker(
        markerId: MarkerId('saved_${pin.id}'),
        position: LatLng(pin.lat, pin.lng),
        icon: _markerIcons[pin.id] ?? BitmapDescriptor.defaultMarkerWithHue(_categoryHue(pin.category)),
        onTap: () => _showSavedPinSheet(pin),
      );
    }).toSet();

    // 내 위치: 파란 점 대신 티고 아바타 마커
    final myLocationMarker = (_currentPos != null && _myLocationIcon != null)
        ? {
            Marker(
              markerId: const MarkerId('my_location'),
              position: _currentPos!,
              icon: _myLocationIcon!,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              zIndexInt: 999,
              consumeTapEvents: true,
            ),
          }
        : <Marker>{};

    // 팔로우한 핀플러의 핀 마커 (선택 중일 때만) — 핀플러별 색상 hue로 구분
    Set<Marker> followedMarkers = {};
    if (_selectedFollowedIndex != null) {
      final pinpler = followedPinplers[_selectedFollowedIndex!];
      final hue = HSLColor.fromColor(pinpler.color).hue;
      followedMarkers = pinpler.pins.map((loc) => Marker(
        markerId: MarkerId('followed_${pinpler.name}_${loc.name}'),
        position: loc.pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(title: loc.name, snippet: pinpler.name),
      )).toSet();
    }

    return {...savedMarkers, ...myLocationMarker, ...followedMarkers};
  }

  // 팔로우 아바타 스트립에서 사람을 선택 — null이면 "나"(내 핀), 아니면 해당 핀플러의 핀으로 지도 전환
  void _selectFollowed(int? index) {
    setState(() => _selectedFollowedIndex = index);
    if (index == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pins = followedPinplers[index].pins;
      if (pins.isEmpty) return;
      final ctrl = await _mapCtrl.future;
      if (pins.length == 1) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(pins.first.pos, 14));
      } else {
        ctrl.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromPoints(pins.map((p) => p.pos).toList()), 80),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _fetchLocation();
    _loadCategories();
    _loadSavedPins();
    _loadMyLocationIcon();
    PinRefreshNotifier.instance.addListener(_loadSavedPins);
  }

  // 내 위치 표시용 커스텀(티고) 마커 아이콘 생성
  Future<void> _loadMyLocationIcon() async {
    final icon = await MarkerBuilder.buildMyLocationMarker();
    if (mounted) setState(() => _myLocationIcon = icon);
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  // 저장된 핀 로드 + 사진이 있는 핀은 커스텀 사진 마커 아이콘 생성, 여행 통계 계산
  Future<void> _loadSavedPins() async {
    final pins = await PinService.getPins();
    if (!mounted) return;

    final pinsWithPhoto = kIsWeb
        ? <PinModel>[]
        : pins.where((p) => p.photoPath != null && p.photoPath!.isNotEmpty).toList();

    final entries = await Future.wait(
      pinsWithPhoto.map((pin) async {
        try {
          final icon = await MarkerBuilder.buildPhotoMarker(pin.photoPath!);
          return MapEntry(pin.id, icon);
        } catch (_) {
          return null;
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      _savedPins = pins;
      _markerIcons = Map.fromEntries(entries.whereType<MapEntry<String, BitmapDescriptor>>());
      _travelStats = TigoService.computeStats(pins);
    });
  }

  @override
  void dispose() {
    PinRefreshNotifier.instance.removeListener(_loadSavedPins);
    _posSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Google Maps 커스텀 스타일 JSON 에셋 로드
  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    if (!mounted) return;
    setState(() => _mapStyle = style);
  }

  // GPS 권한 요청 및 현재 위치 조회 — 성공 시 카메라 이동 및 실시간 위치 추적 시작
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
      _startPositionStream();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = '위치를 가져올 수 없습니다';
      });
    }
  }

  // 위치 변경을 실시간 스트림으로 구독해 현재 위치 마커 갱신
  void _startPositionStream() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPos = LatLng(pos.latitude, pos.longitude));
    });
  }

  // 지도 카메라를 현재 위치로 이동 (위치 없으면 먼저 조회)
  Future<void> _moveToMyLocation() async {
    if (_currentPos == null) {
      await _fetchLocation();
      return;
    }
    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(_currentPos!, 15));
  }

  // 사용자가 저장한 핀의 상세 바텀시트 표시 (드래그로 크기 조절 가능)
  void _showSavedPinSheet(PinModel pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        expand: false,
        builder: (ctx, scrollCtrl) => _SavedPinBottomSheet(
          pin: pin,
          currentPos: _currentPos,
          scrollController: scrollCtrl,
          onNavigate: () {
            Navigator.pop(context);
            _startNavigation(LatLng(pin.lat, pin.lng), pin.title);
          },
          onShare: () {
            Navigator.pop(context);
            _sharePin(LatLng(pin.lat, pin.lng), pin.title, pin.category);
          },
        ),
      ),
    );
  }

  // 경로 안내 시작 — 현재 위치→목적지 도보 경로를 조회해 폴리라인으로 표시
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

  // 진행 중인 경로 안내 취소 및 폴리라인 제거
  void _cancelNavigation() {
    setState(() {
      _isNavigating = false;
      _navLoading = false;
      _polylines = {};
      _navInfo = null;
      _navDestName = null;
    });
  }

  // 핀 위치를 구글 지도 링크와 함께 외부 공유
  void _sharePin(LatLng pos, String name, String category) {
    Share.share(
      '📍 $name ($category)\n'
      'https://maps.google.com/?q=${pos.latitude},${pos.longitude}',
      subject: name,
    );
  }

  // 검색어 변경 시 필터링된 핀들이 모두 보이도록 지도 카메라 자동 이동
  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v);
    if (v.trim().isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final positions = [
        ..._filteredSavedPins.map((p) => LatLng(p.lat, p.lng)),
      ];
      if (positions.isEmpty || !mounted) {
        _showSnack('검색 결과가 없습니다');
        return;
      }
      final ctrl = await _mapCtrl.future;
      if (positions.length == 1) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(positions.first, 15));
      } else {
        ctrl.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromPoints(positions), 80),
        );
      }
    });
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

  // 좌표 목록을 모두 포함하는 최소 경계(bounds) 계산 — 카메라 fit용
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

  // GoogleMap 초기화 + 상단 검색/필터 패널 + 하단 경로 안내/내 위치 버튼을 Stack으로 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _defaultPos, zoom: 13),
            onMapCreated: _mapCtrl.complete,
            style: _mapStyle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          // ── 상단 패널: 검색바 + 카테고리 칩 ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5F3EE),
                    const Color(0xFFF5F3EE).withValues(alpha: 0.92),
                    const Color(0xFFF5F3EE).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.78, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 검색바 + 핀 카운트
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
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
                                onChanged: _onSearchChanged,
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
                          // 팔로우한 사람 지도 보기 토글 버튼
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _showFollowed = !_showFollowed;
                                if (!_showFollowed) _selectedFollowedIndex = null;
                              }),
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: _showFollowed ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                                  ],
                                ),
                                child: Icon(
                                  _showFollowed ? Icons.people_alt_rounded : Icons.people_outline_rounded,
                                  color: _showFollowed ? Colors.white : AppColors.neutral600,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                          // 알림 버튼 — 알림 설정/알림함 화면으로 이동
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                                  ],
                                ),
                                child: const Icon(Icons.notifications_none_rounded, color: AppColors.neutral600, size: 22),
                              ),
                            ),
                          ),
                          // 핀 카운트 뱃지 (필터 활성 시)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: (_searchQuery.isNotEmpty || _selectedCategory != '전체')
                                ? Padding(
                                    key: const ValueKey('badge'),
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutral900,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.location_on, size: 13, color: AppColors.primary),
                                          const SizedBox(height: 1),
                                          Text('$_visiblePinCount',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox(key: ValueKey('empty')),
                          ),
                        ],
                      ),
                    ),
                    // "OOO님의 지도" 배너 — 팔로우한 핀플러의 지도를 보는 중일 때 표시
                    if (_selectedFollowedIndex != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: GestureDetector(
                          onTap: () => _selectFollowed(null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: followedPinplers[_selectedFollowedIndex!].color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                Text(followedPinplers[_selectedFollowedIndex!].emoji, style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${followedPinplers[_selectedFollowedIndex!].name}님의 지도',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('내 지도로 돌아가기',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92))),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // 팔로우한 핀플러 아바타 스트립 (토글 on일 때만)
                    if (_showFollowed)
                      SizedBox(
                        height: 86,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [
                            _FollowedAvatar(
                              label: '나',
                              emoji: '🙂',
                              color: AppColors.primary,
                              isSelected: _selectedFollowedIndex == null,
                              onTap: () => _selectFollowed(null),
                            ),
                            ...List.generate(followedPinplers.length, (i) {
                              final p = followedPinplers[i];
                              return _FollowedAvatar(
                                label: p.name,
                                emoji: p.emoji,
                                color: p.color,
                                isSelected: _selectedFollowedIndex == i,
                                onTap: () => _selectFollowed(i),
                              );
                            }),
                          ],
                        ),
                      ),
                    // 카테고리 칩 (길찾기 중 숨김)
                    if (!_isNavigating && !_navLoading)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          children: ['전체', ..._categories].map((label) {
                            final sel = _selectedCategory == label;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = label),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF1C1C1E) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: sel
                                            ? Colors.black.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.08),
                                        blurRadius: sel ? 8 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                      color: sel ? Colors.white : AppColors.neutral600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
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
          // 내 위치 버튼 — 우측 하단, 카메라 버튼 바로 위
          Positioned(
            bottom: (_isNavigating || _navLoading) ? 234 : 104,
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
          // 핀 등록(카메라) 버튼 — 우측 하단 가장자리, 엄지로 바로 누를 수 있는 위치
          Positioned(
            bottom: (_isNavigating || _navLoading) ? 158 : 28,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatePinScreen())),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
          // 하단 통계 카드(방문한 도시/발톱 자국/촬영한 사진)는 지도에서 일단 제거 —
          // 다른 화면으로 옮길지 논의 중, _MapStatsCard 위젯 자체는 재사용을 위해 남겨둠
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

// ── 하단 통계 카드 ──────────────────────────────────────────────────────────
class _MapStatsCard extends StatelessWidget {
  final TravelStats stats;
  const _MapStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _StatItem(label: '방문한 도시', value: '${stats.visitedCities}'),
          _Divider(),
          _StatItem(label: '남긴 발톱 자국', value: '${stats.footprints}'),
          _Divider(),
          _StatItem(label: '촬영한 사진', value: '${stats.photos}'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFF8A00))),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFEEEEEE));
  }
}

// ──────────────────────────────────────────────
// 팔로우 지도 아바타 스트립 항목 ("나" 또는 팔로우한 핀플러 한 명)
// ──────────────────────────────────────────────
class _FollowedAvatar extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FollowedAvatar({
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.neutral900 : Colors.white,
                    width: isSelected ? 2.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.20 : 0.10),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppColors.neutral900 : AppColors.neutral500,
                ),
              ),
            ],
          ),
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
  final ScrollController scrollController;

  const _SavedPinBottomSheet({
    required this.pin,
    required this.currentPos,
    required this.onNavigate,
    required this.onShare,
    required this.scrollController,
  });

  // 현재 위치에서 핀까지의 거리를 km/m 단위 문자열로 변환
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 히어로 사진
          if (pin.photoPath != null && !kIsWeb)
            Image.file(
              File(pin.photoPath!),
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          // 현재 위치 거리 배너
          if (dist != null)
            Container(
              color: AppColors.primary.withValues(alpha: 0.07),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '현재 위치에서 $dist',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          // 핀 정보
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 + 카테고리 배지
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pin.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(pin.category,
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 설명 (전체 표시, 줄임 없음)
                if (pin.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(pin.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.6)),
                ],
                // 등급 정보
                if (pin.ratings != null && pin.ratings!.isNotEmpty)
                  _PinRatingsDisplay(ratings: pin.ratings!, category: pin.category),
                const SizedBox(height: 20),
                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.directions_walk_rounded, size: 18, color: Colors.white),
                        label: const Text('길찾기',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52, height: 52,
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
    );
  }
}

// ──────────────────────────────────────────────
// 핀 등급 표시 위젯
// ──────────────────────────────────────────────
class _PinRatingsDisplay extends StatelessWidget {
  final Map<String, double> ratings;
  final String category;

  const _PinRatingsDisplay({required this.ratings, required this.category});

  // 평가 단계(1~5)에 따라 초록→빨강으로 변하는 색상 반환
  Color _levelColor(double val) {
    if (val <= 1) return const Color(0xFF16A34A);
    if (val <= 2) return const Color(0xFF65A30D);
    if (val == 3) return const Color(0xFFCA8A04);
    if (val == 4) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final dims = PinRatingSchema.forCategory(category);
    final relevant = dims.where((d) => ratings.containsKey(d.key)).toList();
    if (relevant.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0EDE8)),
        const SizedBox(height: 14),
        Row(
          children: const [
            Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.primary),
            SizedBox(width: 5),
            Text('등급 정보',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
          ],
        ),
        const SizedBox(height: 10),
        ...relevant.map((dim) {
          final val = ratings[dim.key]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(dim.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                SizedBox(
                  width: 48,
                  child: Text(dim.label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral600)),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(5, (i) {
                      final level = i + 1;
                      final isSelected = val == level.toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.neutral100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.neutral400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Text(
                  dim.labelFor(val),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _levelColor(val),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
