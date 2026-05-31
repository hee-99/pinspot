import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerBuilder {
  static const double _size = 90.0;

  static Future<BitmapDescriptor> buildPhotoMarker(String imagePath) =>
      buildClusterMarker(imagePath, 1);

  /// Builds a circular photo marker.
  /// If [count] > 1, draws a count badge ("N명") below the circle.
  static Future<BitmapDescriptor> buildClusterMarker(
    String? imagePath,
    int count, {
    ui.Color accent = const ui.Color(0xFF16A34A),
  }) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    const double cs = _size;
    const double badgeH = 22.0;
    const double gap = 3.0;
    final bool showBadge = count > 1;
    final double totalH = showBadge ? cs + gap + badgeH : cs;

    ui.Image? photo;
    if (imagePath != null) {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80, targetHeight: 80);
        final frame = await codec.getNextFrame();
        photo = frame.image;
      } catch (_) {}
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Outer accent ring
    canvas.drawCircle(
      ui.Offset(cs / 2, cs / 2),
      cs / 2,
      ui.Paint()..color = accent..isAntiAlias = true,
    );
    // White inner ring
    canvas.drawCircle(
      ui.Offset(cs / 2, cs / 2),
      cs / 2 - 3,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF)..isAntiAlias = true,
    );

    if (photo != null) {
      canvas.save();
      canvas.clipPath(
        ui.Path()..addOval(
          ui.Rect.fromCircle(center: ui.Offset(cs / 2, cs / 2), radius: cs / 2 - 5),
        ),
      );
      canvas.drawImageRect(
        photo,
        ui.Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
        ui.Rect.fromLTWH(5, 5, cs - 10, cs - 10),
        ui.Paint()..isAntiAlias = true,
      );
      canvas.restore();
    }

    if (showBadge) {
      final label = '$count명';
      final badgeY = cs + gap;

      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: ui.TextAlign.center, fontSize: 11),
      )
        ..pushStyle(ui.TextStyle(
          color: const ui.Color(0xFFFFFFFF),
          fontSize: 11,
          fontWeight: ui.FontWeight.w700,
        ))
        ..addText(label);
      final para = pb.build()
        ..layout(ui.ParagraphConstraints(width: cs));

      final textW = math.min(para.maxIntrinsicWidth + 18, cs);
      final badgeX = (cs - textW) / 2;

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(badgeX, badgeY, textW, badgeH),
          const ui.Radius.circular(11),
        ),
        ui.Paint()..color = accent..isAntiAlias = true,
      );
      canvas.drawParagraph(
        para,
        ui.Offset(badgeX + (textW - para.maxIntrinsicWidth) / 2, badgeY + (badgeH - 13) / 2),
      );
    }

    final picture = recorder.endRecording();
    final result = await picture.toImage(cs.toInt(), totalH.toInt());
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
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
