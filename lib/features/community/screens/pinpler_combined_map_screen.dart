import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'pinpler_ranking_screen.dart';

class PinplerCombinedMapScreen extends StatefulWidget {
  final List<PinplerData> pinplers;
  final String category;

  const PinplerCombinedMapScreen({
    super.key,
    required this.pinplers,
    required this.category,
  });

  @override
  State<PinplerCombinedMapScreen> createState() => _PinplerCombinedMapScreenState();
}

class _PinplerCombinedMapScreenState extends State<PinplerCombinedMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<int> _hiddenIndexes = {};

  void _togglePinpler(int index) {
    setState(() {
      if (_hiddenIndexes.contains(index)) {
        _hiddenIndexes.remove(index);
      } else {
        _hiddenIndexes.add(index);
      }
    });
  }

  LatLng get _center {
    final allPins = widget.pinplers.expand((p) => p.pins).toList();
    if (allPins.isEmpty) return const LatLng(37.5665, 126.9780);
    final lat = allPins.map((p) => p.lat).reduce((a, b) => a + b) / allPins.length;
    final lng = allPins.map((p) => p.lng).reduce((a, b) => a + b) / allPins.length;
    return LatLng(lat, lng);
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    for (int i = 0; i < widget.pinplers.length; i++) {
      if (_hiddenIndexes.contains(i)) continue;
      final pinpler = widget.pinplers[i];
      for (final pin in pinpler.pins) {
        markers.add(Marker(
          markerId: MarkerId('${pinpler.name}_${pin.name}'),
          position: LatLng(pin.lat, pin.lng),
          infoWindow: InfoWindow(title: pin.name, snippet: '${pinpler.name} · ${pin.category}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(_colorToHue(pinpler.avatarColor)),
        ));
      }
    }
    return markers;
  }

  double _colorToHue(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.hue;
  }

  @override
  Widget build(BuildContext context) {
    final totalPins = widget.pinplers.fold(0, (sum, p) => sum + p.pins.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pinplers.length}명 핀플 지도', style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 3),
                  Text('총 $totalPins개 핀', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 핀플 토글 바
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(widget.pinplers.length, (i) {
                  final pinpler = widget.pinplers[i];
                  final isVisible = !_hiddenIndexes.contains(i);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _togglePinpler(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isVisible ? pinpler.avatarColor : AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isVisible ? pinpler.avatarColor : const Color(0xFFDDDDDD)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              child: Text(pinpler.name[0], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pinpler.name,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isVisible ? Colors.white : AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pinpler.pins.length}핀',
                              style: TextStyle(fontSize: 10, color: isVisible ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // 실제 Google Maps
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 10.5),
              onMapCreated: (c) => _controller.complete(c),
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          // 하단 범례
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('핀플 범례', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...List.generate(widget.pinplers.length, (i) {
                  final p = widget.pinplers[i];
                  final isVisible = !_hiddenIndexes.contains(i);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isVisible ? p.avatarColor : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isVisible ? AppTheme.textPrimary : AppTheme.textSecondary)),
                        const SizedBox(width: 4),
                        Text(p.handle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        const Spacer(),
                        Text('${p.pins.length}개 핀', style: TextStyle(fontSize: 11, color: isVisible ? p.avatarColor : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
