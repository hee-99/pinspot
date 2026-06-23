import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerBuilder {
  // 사진 핀 마커: 둥근 사각형 사진 + 아래 꼭지 (위치핀 형태)
  static Future<BitmapDescriptor> buildPhotoMarker(String imagePath) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    const double sz     = 100.0;  // 사각형 크기
    const double radius = 14.0;   // 모서리 반경
    const double tip    = 16.0;   // 꼭지 높이
    const double border = 3.5;    // 흰 테두리 두께
    const double totalH = sz + tip;
    const double w      = sz;

    ui.Image? photo;
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 100, targetHeight: 100);
      final frame = await codec.getNextFrame();
      photo = frame.image;
    } catch (_) {}

    final recorder = ui.PictureRecorder();
    final canvas   = ui.Canvas(recorder);

    // 그림자
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x44000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    _drawPinShape(canvas, w, sz, tip, radius, shadowPaint, offsetY: 3);

    // 흰 테두리
    final borderPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    _drawPinShape(canvas, w, sz, tip, radius, borderPaint);

    // 사진 클립
    canvas.save();
    final clipPath = _pinPath(w, sz, tip, radius - border + 1,
        insetX: border, insetY: border);
    canvas.clipPath(clipPath);

    if (photo != null) {
      canvas.drawImageRect(
        photo,
        ui.Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
        ui.Rect.fromLTWH(border, border, w - border * 2, sz - border * 2),
        ui.Paint()..isAntiAlias = true,
      );
    } else {
      // 사진 없을 때 주황 배경 + 카메라 아이콘
      canvas.drawRect(
        ui.Rect.fromLTWH(border, border, w - border * 2, sz - border * 2),
        ui.Paint()..color = const ui.Color(0xFFFF8A00),
      );
    }
    canvas.restore();

    final picture = recorder.endRecording();
    final img  = await picture.toImage(w.toInt(), totalH.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  static void _drawPinShape(
    ui.Canvas canvas, double w, double sz, double tip, double r,
    ui.Paint paint, {double offsetY = 0}
  ) {
    final path = _pinPath(w, sz, tip, r, offsetY: offsetY);
    canvas.drawPath(path, paint);
  }

  static ui.Path _pinPath(
    double w, double sz, double tip, double r, {
    double insetX = 0, double insetY = 0, double offsetY = 0,
  }) {
    final left   = insetX;
    final top    = insetY + offsetY;
    final right  = w - insetX;
    final bottom = sz - insetY + offsetY;
    final mid    = w / 2;

    return ui.Path()
      ..moveTo(left + r, top)
      ..lineTo(right - r, top)
      ..arcToPoint(ui.Offset(right, top + r),
          radius: ui.Radius.circular(r))
      ..lineTo(right, bottom - r)
      ..arcToPoint(ui.Offset(right - r, bottom),
          radius: ui.Radius.circular(r))
      ..lineTo(mid + 10, bottom)
      ..lineTo(mid, bottom + tip - insetY)   // 꼭지 끝
      ..lineTo(mid - 10, bottom)
      ..lineTo(left + r, bottom)
      ..arcToPoint(ui.Offset(left, bottom - r),
          radius: ui.Radius.circular(r))
      ..lineTo(left, top + r)
      ..arcToPoint(ui.Offset(left + r, top),
          radius: ui.Radius.circular(r))
      ..close();
  }

  /// 클러스터 마커 (여러 핀 묶음)
  static Future<BitmapDescriptor> buildClusterMarker(
    String? imagePath,
    int count, {
    ui.Color accent = const ui.Color(0xFFFF8A00),
  }) async {
    if (count == 1 && imagePath != null) return buildPhotoMarker(imagePath);
    if (kIsWeb) return BitmapDescriptor.defaultMarkerWithHue(30);

    const double cs = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas   = ui.Canvas(recorder);

    canvas.drawCircle(ui.Offset(cs / 2, cs / 2), cs / 2,
        ui.Paint()..color = accent..isAntiAlias = true);
    canvas.drawCircle(ui.Offset(cs / 2, cs / 2), cs / 2 - 4,
        ui.Paint()..color = const ui.Color(0xFFFFFFFF)..isAntiAlias = true);

    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: ui.TextAlign.center, fontSize: 20),
    )
      ..pushStyle(ui.TextStyle(
        color: accent, fontSize: 20, fontWeight: ui.FontWeight.w900,
      ))
      ..addText('$count');
    final para = pb.build()..layout(ui.ParagraphConstraints(width: cs));
    canvas.drawParagraph(para, ui.Offset(0, (cs - 24) / 2));

    final picture = recorder.endRecording();
    final img  = await picture.toImage(cs.toInt(), cs.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarkerWithHue(30);
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  /// Groups [items] into clusters where all members are within [radiusMeters] of the first member.
  static List<List<T>> clusterByLocation<T>({
    required List<T> items,
    required double Function(T) getLat,
    required double Function(T) getLng,
    double radiusMeters = 80,
  }) {
    final used = <int>{};
    final result = <List<T>>[];
    for (int i = 0; i < items.length; i++) {
      if (used.contains(i)) continue;
      final group = [items[i]];
      for (int j = i + 1; j < items.length; j++) {
        if (used.contains(j)) continue;
        if (_haversine(
              getLat(items[i]), getLng(items[i]),
              getLat(items[j]), getLng(items[j]),
            ) <=
            radiusMeters) {
          group.add(items[j]);
          used.add(j);
        }
      }
      used.add(i);
      result.add(group);
    }
    return result;
  }

  /// Draws a TIGO footprint marker: orange circle with 3 white claw slashes.
  static Future<BitmapDescriptor> buildFootprintMarker({
    ui.Color color = const ui.Color(0xFFFF8A00),
  }) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarkerWithHue(30);

    const double cs = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Orange circle background
    canvas.drawCircle(
      const ui.Offset(cs / 2, cs / 2),
      cs / 2,
      ui.Paint()..color = color..isAntiAlias = true,
    );
    // White inner ring
    canvas.drawCircle(
      const ui.Offset(cs / 2, cs / 2),
      cs / 2 - 3,
      ui.Paint()
        ..color = const ui.Color(0x33FFFFFF)
        ..isAntiAlias = true,
    );

    // 3 claw slashes (diagonal, top-right → bottom-left direction)
    final clawPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 3.5
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke
      ..isAntiAlias = true;

    final slashOffsets = [-9.0, 0.0, 9.0];
    for (final dx in slashOffsets) {
      final cx = cs / 2 + dx;
      canvas.drawLine(
        ui.Offset(cx + 7, 13),
        ui.Offset(cx - 7, cs - 13),
        clawPaint,
      );
    }

    final picture = recorder.endRecording();
    final result = await picture.toImage(cs.toInt(), cs.toInt());
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarkerWithHue(30);
    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final a = lat1 * (math.pi / 180);
    final b = lat2 * (math.pi / 180);
    final da = (lat2 - lat1) * (math.pi / 180);
    final dl = (lng2 - lng1) * (math.pi / 180);
    final x = math.sin(da / 2) * math.sin(da / 2) +
        math.cos(a) * math.cos(b) * math.sin(dl / 2) * math.sin(dl / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }
}
