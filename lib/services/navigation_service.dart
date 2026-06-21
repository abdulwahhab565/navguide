import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../config/app_config.dart';

class CampusRoute {
  final List<LatLng> polylinePoints;
  final String distanceText; // e.g. "450 m"
  final double distanceValue; // in meters
  final String durationText; // e.g. "5 mins"
  final int durationMinutes; // in minutes
  final List<String> instructions; // turn-by-turn steps

  CampusRoute({
    required this.polylinePoints,
    required this.distanceText,
    required this.distanceValue,
    required this.durationText,
    required this.durationMinutes,
    required this.instructions,
  });
}

class NavigationService {
  // Local campus graph for offline / API fallback routing
  static final Map<String, LatLng> _waypoints = {
    'admin_block': const LatLng(7.3495, -2.3435),
    'engineering_block': const LatLng(7.3502, -2.3442),
    'it_directorate': const LatLng(7.3488, -2.3425),
    'library': const LatLng(7.3491, -2.3431),
    'cafeteria': const LatLng(7.3475, -2.3432),
    'clinic': const LatLng(7.3510, -2.3420),
    'lecture_hall_a': const LatLng(7.3498, -2.3415),
    'lecture_hall_b': const LatLng(7.3505, -2.3430),
    'science_lecture_hall': const LatLng(7.3482, -2.3445),
    'washrooms_library': const LatLng(7.3490, -2.3429),
    'washrooms_engineering': const LatLng(7.3500, -2.3440),
    // Intermediate pathway intersections
    'junction_admin_library': const LatLng(7.3493, -2.3433),
    'junction_admin_eng': const LatLng(7.3499, -2.3439),
    'junction_lib_cafeteria': const LatLng(7.3483, -2.34315),
    'junction_clinic_ltb_b': const LatLng(7.3508, -2.3425),
    // New locations
    'main_gate': const LatLng(7.3462, -2.3415),
    'vc_office': const LatLng(7.3496, -2.3436),
    'registrar_office': const LatLng(7.3494, -2.3434),
    'comp_science': const LatLng(7.3508, -2.3446),
    'natural_resources': const LatLng(7.3485, -2.3450),
    'hostel_men': const LatLng(7.3525, -2.3455),
    'hostel_women': const LatLng(7.3530, -2.3450),
    'sports_complex': const LatLng(7.3520, -2.3410),
    'atm': const LatLng(7.3480, -2.3430),
    'chapel': const LatLng(7.3470, -2.3440),
  };

  // Graph adjacencies: maps a waypoint ID to a list of connected waypoint IDs
  static final Map<String, List<String>> _adjacencies = {
    'admin_block': [
      'junction_admin_library',
      'junction_admin_eng',
      'lecture_hall_b',
      'vc_office',
      'registrar_office',
      'atm'
    ],
    'engineering_block': [
      'junction_admin_eng',
      'washrooms_engineering',
      'lecture_hall_b',
      'comp_science'
    ],
    'it_directorate': ['library', 'cafeteria', 'lecture_hall_a'],
    'library': [
      'junction_admin_library',
      'it_directorate',
      'junction_lib_cafeteria',
      'washrooms_library'
    ],
    'cafeteria': [
      'junction_lib_cafeteria',
      'science_lecture_hall',
      'it_directorate',
      'main_gate',
      'natural_resources',
      'atm',
      'chapel'
    ],
    'clinic': ['junction_clinic_ltb_b', 'lecture_hall_a', 'sports_complex'],
    'lecture_hall_a': ['it_directorate', 'clinic'],
    'lecture_hall_b': [
      'admin_block',
      'engineering_block',
      'junction_clinic_ltb_b',
      'comp_science',
      'hostel_men',
      'hostel_women'
    ],
    'science_lecture_hall': ['cafeteria', 'natural_resources'],
    'washrooms_library': ['library'],
    'washrooms_engineering': ['engineering_block'],

    // Intersections
    'junction_admin_library': ['admin_block', 'library'],
    'junction_admin_eng': ['admin_block', 'engineering_block'],
    'junction_lib_cafeteria': ['library', 'cafeteria'],
    'junction_clinic_ltb_b': ['clinic', 'lecture_hall_b'],

    // New locations
    'main_gate': ['cafeteria'],
    'vc_office': ['admin_block'],
    'registrar_office': ['admin_block'],
    'comp_science': ['engineering_block', 'lecture_hall_b'],
    'natural_resources': ['cafeteria', 'science_lecture_hall'],
    'hostel_men': ['hostel_women', 'lecture_hall_b'],
    'hostel_women': ['hostel_men', 'lecture_hall_b'],
    'sports_complex': ['clinic'],
    'atm': ['admin_block', 'cafeteria'],
    'chapel': ['cafeteria'],
  };

  // Get route between starting point and destination
  Future<CampusRoute> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // If API key is placeholder, or if web request fails, use local A* algorithm immediately
    if (AppConfig.googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      print(
          'Google Maps API Key not configured. Using local A* navigation engine.');
      return _calculateLocalRoute(origin, destination);
    }

    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking'
        '&key=${AppConfig.googleMapsApiKey}';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final String distanceText = leg['distance']['text'];
          final double distanceValue =
              (leg['distance']['value'] as num).toDouble();
          final String durationText = leg['duration']['text'];
          final int durationMinutes =
              ((leg['duration']['value'] as num).toDouble() / 60).round();

          // Decode polyline points
          final String encodedPolyline = route['overview_polyline']['points'];
          final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

          // Parse turn-by-turn instructions
          final List<String> instructions = [];
          for (var step in leg['steps']) {
            String rawInstruction = step['html_instructions'] ?? '';
            // Remove HTML tags from directions
            String cleanInstruction =
                rawInstruction.replaceAll(RegExp(r'<[^>]*>'), '');
            instructions.add(cleanInstruction);
          }

          return CampusRoute(
            polylinePoints: polylinePoints,
            distanceText: distanceText,
            distanceValue: distanceValue,
            durationText: durationText,
            durationMinutes: durationMinutes,
            instructions: instructions,
          );
        } else {
          print(
              'Google Directions API returned error: ${data['status']}. Falling back to A*.');
          return _calculateLocalRoute(origin, destination);
        }
      } else {
        print('HTTP error contacting Directions API. Falling back to A*.');
        return _calculateLocalRoute(origin, destination);
      }
    } catch (e) {
      print(
          'Network exception during routing: $e. Falling back to local route.');
      return _calculateLocalRoute(origin, destination);
    }
  }

  // Parses encoded polyline strings from Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Helper to retrieve corrected waypoint LatLng
  LatLng _getWaypoint(String id) {
    return AppConfig.correctCoordinate(_waypoints[id]!);
  }

  // LOCAL A* PATHFINDING ALGORITHM
  CampusRoute _calculateLocalRoute(LatLng origin, LatLng destination) {
    // 1. Find nearest waypoints to origin and destination
    String originNode = _findNearestWaypoint(origin);
    String destNode = _findNearestWaypoint(destination);

    List<String> pathNodes = [];
    if (originNode == destNode) {
      pathNodes = [originNode];
    } else {
      pathNodes = _performAStarSearch(originNode, destNode);
    }

    // 2. Assemble polyline path points
    List<LatLng> pathPoints = [];
    pathPoints.add(origin); // Start exactly at user's position
    for (String nodeId in pathNodes) {
      pathPoints.add(_getWaypoint(nodeId));
    }
    pathPoints.add(destination); // End exactly at destination location

    // 3. Calculate distance and walking times
    double totalDistance = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      totalDistance += _haversineDistance(pathPoints[i], pathPoints[i + 1]);
    }

    int durationMinutes =
        (totalDistance / 1.2 / 60).round(); // 1.2 m/s walking speed
    if (durationMinutes < 1) durationMinutes = 1;

    String distanceText = totalDistance >= 1000
        ? '${(totalDistance / 1000).toStringAsFixed(1)} km'
        : '${totalDistance.round()} m';
    String durationText =
        '$durationMinutes min${durationMinutes > 1 ? 's' : ''}';

    // 4. Generate step instructions based on segments
    List<String> instructions = [];
    instructions.add('Start walking toward the nearest campus path.');

    for (int i = 1; i < pathNodes.length; i++) {
      String from = pathNodes[i - 1];
      String to = pathNodes[i];
      String fromName = _getReadableNodeName(from);
      String toName = _getReadableNodeName(to);
      instructions.add('Head from $fromName towards $toName.');
    }

    instructions.add('Arrive at your destination.');

    return CampusRoute(
      polylinePoints: pathPoints,
      distanceText: distanceText,
      distanceValue: totalDistance,
      durationText: durationText,
      durationMinutes: durationMinutes,
      instructions: instructions,
    );
  }

  String _findNearestWaypoint(LatLng pos) {
    String nearestId = 'admin_block';
    double minDistance = double.infinity;

    _waypoints.forEach((id, coord) {
      double dist = _haversineDistance(pos, AppConfig.correctCoordinate(coord));
      if (dist < minDistance) {
        minDistance = dist;
        nearestId = id;
      }
    });

    return nearestId;
  }

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth radius in meters
    double dLat = _toRadians(p2.latitude - p1.latitude);
    double dLng = _toRadians(p2.longitude - p1.longitude);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  // A* Pathfinding implementation
  List<String> _performAStarSearch(String start, String goal) {
    List<String> openSet = [start];
    Map<String, String> cameFrom = {};

    Map<String, double> gScore = {};
    for (var node in _waypoints.keys) {
      gScore[node] = double.infinity;
    }
    gScore[start] = 0;

    Map<String, double> fScore = {};
    for (var node in _waypoints.keys) {
      fScore[node] = double.infinity;
    }
    fScore[start] = _haversineDistance(_getWaypoint(start), _getWaypoint(goal));

    while (openSet.isNotEmpty) {
      // Find node in openSet with lowest fScore
      String current = openSet.first;
      double lowestF = fScore[current] ?? double.infinity;
      for (String node in openSet) {
        double nodeF = fScore[node] ?? double.infinity;
        if (nodeF < lowestF) {
          lowestF = nodeF;
          current = node;
        }
      }

      if (current == goal) {
        // Reconstruct path
        List<String> totalPath = [current];
        while (cameFrom.containsKey(current)) {
          current = cameFrom[current]!;
          totalPath.insert(0, current);
        }
        return totalPath;
      }

      openSet.remove(current);

      List<String> neighbors = _adjacencies[current] ?? [];
      for (String neighbor in neighbors) {
        double tentativeGScore = (gScore[current] ?? double.infinity) +
            _haversineDistance(_getWaypoint(current), _getWaypoint(neighbor));

        if (tentativeGScore < (gScore[neighbor] ?? double.infinity)) {
          cameFrom[neighbor] = current;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] = tentativeGScore +
              _haversineDistance(_getWaypoint(neighbor), _getWaypoint(goal));

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    // Return direct path if pathfinding fails
    return [start, goal];
  }

  String _getReadableNodeName(String nodeId) {
    switch (nodeId) {
      case 'admin_block':
        return 'Administration Block';
      case 'engineering_block':
        return 'Engineering Block';
      case 'it_directorate':
        return 'IT Directorate';
      case 'library':
        return 'University Library';
      case 'cafeteria':
        return 'Campus Cafeteria';
      case 'clinic':
        return 'Campus Clinic';
      case 'lecture_hall_a':
        return 'Lecture Hall Block A';
      case 'lecture_hall_b':
        return 'Lecture Hall Block B';
      case 'science_lecture_hall':
        return 'Science Lecture Hall';
      case 'washrooms_library':
        return 'Washroom (Near Library)';
      case 'washrooms_engineering':
        return 'Washroom (Engineering)';
      case 'junction_admin_library':
        return 'path near Administration';
      case 'junction_admin_eng':
        return 'path near Engineering';
      case 'junction_lib_cafeteria':
        return 'path near Cafeteria';
      case 'junction_clinic_ltb_b':
        return 'path near Clinic';
      case 'main_gate':
        return 'Main Gate';
      case 'vc_office':
        return 'Vice Chancellor\'s Office';
      case 'registrar_office':
        return 'Registrar\'s Office';
      case 'comp_science':
        return 'Department of Computer Science';
      case 'natural_resources':
        return 'Faculty of Natural Resources';
      case 'hostel_men':
        return 'Student Hostel (Men)';
      case 'hostel_women':
        return 'Student Hostel (Women)';
      case 'sports_complex':
        return 'Sports Complex';
      case 'atm':
        return 'Bank/ATM';
      case 'chapel':
        return 'Small Chapel';
      default:
        return 'Campus walkway';
    }
  }
}
