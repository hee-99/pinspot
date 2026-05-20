import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;

  const DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
  });
}

class DirectionsService {
  static const _apiKey = 'AIzaSyAyEl5Vc30X00H4SX6Px6CdxvLTeDPqJFA';

  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=walking'
      '&key=$_apiKey',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final leg = (route['legs'] as List)[0] as Map<String, dynamic>;
      final encoded = (route['overview_polyline'] as Map)['points'] as String;

      return DirectionsResult(
        polylinePoints: _decodePolyline(encoded),
        distance: (leg['distance'] as Map)['text'] as String,
        duration: (leg['duration'] as Map)['text'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}
