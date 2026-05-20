import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerBuilder {
  static const double _size = 90.0;

  static Future<BitmapDescriptor> buildPhotoMarker(String imagePath) async {
    if (kIsWeb) return BitmapDescriptor.defaultMarkerWithHue(14.0);
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 80, targetHeight: 80);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.drawCircle(
        ui.Offset(_size / 2, _size / 2),
        _size / 2,
        ui.Paint()..color = const ui.Color(0xFFFF7043)..isAntiAlias = true,
      );
      canvas.drawCircle(
        ui.Offset(_size / 2, _size / 2),
        _size / 2 - 3,
        ui.Paint()..color = const ui.Color(0xFFFFFFFF)..isAntiAlias = true,
      );
      canvas.clipPath(
        ui.Path()..addOval(
          ui.Rect.fromCircle(center: ui.Offset(_size / 2, _size / 2), radius: _size / 2 - 5),
        ),
      );
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        ui.Rect.fromLTWH(5, 5, _size - 10, _size - 10),
        ui.Paint()..isAntiAlias = true,
      );

      final picture = recorder.endRecording();
      final result = await picture.toImage(_size.toInt(), _size.toInt());
      final data = await result.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return BitmapDescriptor.defaultMarkerWithHue(14.0);
      return BitmapDescriptor.bytes(data.buffer.asUint8List());
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(14.0);
    }
  }
}
