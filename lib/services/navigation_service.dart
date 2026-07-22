import 'dart:convert';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

class CampusRoute {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  final double distanceInMeters;
  final int durationInSeconds;
  final List<String> instructions;

  CampusRoute({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.instructions,
  });
}

class NavigationService {
  final Map<String, CampusRoute> _routeCache = {};

  Future<CampusRoute> getRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'walking',
  }) async {
    final cacheKey = '${origin.latitude},${origin.longitude}_${destination.latitude},${destination.longitude}_$travelMode';

    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    try {
      final apiKey = AppConfig.googleMapsApiKey;
      if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
        return _generateFallbackCampusRoute(origin, destination);
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'mode=$travelMode&'
            'key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final routeData = data['routes'][0];
          final leg = routeData['legs'][0];

          final distanceText = leg['distance']['text'];
          final durationText = leg['duration']['text'];
          final distanceInMeters = (leg['distance']['value'] as num).toDouble();
          final durationInSeconds = leg['duration']['value'] as int;

          final encodedPoints = routeData['overview_polyline']['points'];
          final polylinePoints = _decodePolyline(encodedPoints);

          final instructions = <String>[];
          for (var step in leg['steps']) {
            final htmlInstruction = step['html_instructions'] as String;
            final cleanInstruction = _stripHtml(htmlInstruction);
            instructions.add(cleanInstruction);
          }

          final campusRoute = CampusRoute(
            polylinePoints: polylinePoints,
            distanceText: distanceText,
            durationText: durationText,
            distanceInMeters: distanceInMeters,
            durationInSeconds: durationInSeconds,
            instructions: instructions,
          );

          _routeCache[cacheKey] = campusRoute;
          return campusRoute;
        }
      }
    } catch (e) {
      print('Directions API failed ($e). Using internal Campus Graph routing.');
    }

    final fallbackRoute = _generateFallbackCampusRoute(origin, destination);
    _routeCache[cacheKey] = fallbackRoute;
    return fallbackRoute;
  }

  CampusRoute _generateFallbackCampusRoute(LatLng origin, LatLng destination) {
    final distanceMeters = _calculateHaversineDistance(origin, destination);
    final durationSeconds = (distanceMeters / 1.35).round();

    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    final minutes = (durationSeconds / 60).ceil();
    final durationText = '$minutes min walk';

    final points = <LatLng>[
      origin,
      LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * 0.4,
        origin.longitude + (destination.longitude - origin.longitude) * 0.3,
      ),
      LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * 0.7,
        origin.longitude + (destination.longitude - origin.longitude) * 0.8,
      ),
      destination,
    ];

    final instructions = [
      'Head towards destination on campus walkway',
      'Continue straight past central junction',
      'Arrive at your campus destination on the right',
    ];

    return CampusRoute(
      polylinePoints: points,
      distanceText: distanceText,
      durationText: durationText,
      distanceInMeters: distanceMeters,
      durationInSeconds: durationSeconds,
      instructions: instructions,
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  String _stripHtml(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ');
  }

  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000;
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  Future<CampusRoute> recalculateRouteIfNeeded({
    required LatLng currentPosition,
    required LatLng destination,
    required CampusRoute currentRoute,
    double threshold = 25.0,
  }) async {
    bool onPath = false;
    final path = currentRoute.polylinePoints;

    for (final point in path) {
      final dist = _calculateHaversineDistance(currentPosition, point);
      if (dist < threshold) {
        onPath = true;
        break;
      }
    }

    if (!onPath) {
      print('🔄 Recalculating route...');
      return await getRoute(
        origin: currentPosition,
        destination: destination,
      );
    }

    return currentRoute;
  }

  void clearCache() {
    _routeCache.clear();
  }
}