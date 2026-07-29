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

    if (_shouldUseCampusGraph(origin, destination)) {
      final campusRoute = _generateCampusGraphRoute(origin, destination);
      _routeCache[cacheKey] = campusRoute;
      return campusRoute;
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

    final fallbackRoute = _shouldUseCampusGraph(origin, destination)
        ? _generateCampusGraphRoute(origin, destination)
        : _generateFallbackCampusRoute(origin, destination);
    _routeCache[cacheKey] = fallbackRoute;
    return fallbackRoute;
  }

  bool _shouldUseCampusGraph(LatLng origin, LatLng destination) {
    if (AppConfig.isWithinCampus(origin) || AppConfig.isWithinCampus(destination)) {
      return true;
    }

    final campusCenter = AppConfig.campusCenter;
    final originDistance = _calculateHaversineDistance(origin, campusCenter);
    final destinationDistance = _calculateHaversineDistance(destination, campusCenter);
    return originDistance <= 4000 || destinationDistance <= 4000;
  }

  CampusRoute _generateCampusGraphRoute(LatLng origin, LatLng destination) {
    final startNodeId = _findClosestNode(origin);
    final endNodeId = _findClosestNode(destination);

    if (startNodeId == null || endNodeId == null || startNodeId == endNodeId) {
      return _generateFallbackCampusRoute(origin, destination);
    }

    final pathNodeIds = _findShortestPath(startNodeId, endNodeId);
    if (pathNodeIds.isEmpty) {
      return _generateFallbackCampusRoute(origin, destination);
    }

    final points = <LatLng>[origin];
    final startNode = AppConfig.getNodeById(startNodeId);
    final endNode = AppConfig.getNodeById(endNodeId);

    if (startNode != null) {
      points.addAll(_interpolatePointsBetween(origin, startNode.position, segments: 3));
    }

    for (var index = 0; index < pathNodeIds.length; index++) {
      final nodeId = pathNodeIds[index];
      final node = AppConfig.getNodeById(nodeId);
      if (node == null) continue;

      if (index == 0) {
        points.add(node.position);
      } else {
        final previousNode = AppConfig.getNodeById(pathNodeIds[index - 1]);
        if (previousNode != null) {
          points.addAll(_interpolatePointsBetween(previousNode.position, node.position, segments: 3));
        }
        points.add(node.position);
      }
    }

    if (endNode != null) {
      if (pathNodeIds.isNotEmpty) {
        final lastNode = AppConfig.getNodeById(pathNodeIds.last);
        if (lastNode != null) {
          points.addAll(_interpolatePointsBetween(lastNode.position, endNode.position, segments: 3));
        }
      }
      points.addAll(_interpolatePointsBetween(endNode.position, destination, segments: 3));
    }

    points.add(destination);

    final cleanedPoints = _deduplicatePoints(points);
    final distanceMeters = _calculateCampusRouteDistance(origin, destination, pathNodeIds);
    final durationSeconds = (distanceMeters / 1.35).round();

    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    final minutes = (durationSeconds / 60).ceil();
    final durationText = '$minutes min walk';

    final instructions = _buildCampusInstructions(pathNodeIds);

    return CampusRoute(
      polylinePoints: cleanedPoints,
      distanceText: distanceText,
      durationText: durationText,
      distanceInMeters: distanceMeters,
      durationInSeconds: durationSeconds,
      instructions: instructions,
    );
  }

  List<String> _buildCampusInstructions(List<String> pathNodeIds) {
    if (pathNodeIds.isEmpty) {
      return ['Follow the connected campus walkway to your destination'];
    }

    final instructions = <String>['Follow the internal campus walkway network'];
    for (var index = 0; index < pathNodeIds.length - 1; index++) {
      final fromNode = AppConfig.getNodeById(pathNodeIds[index]);
      final toNode = AppConfig.getNodeById(pathNodeIds[index + 1]);
      final fromLabel = fromNode?.label ?? 'campus junction';
      final toLabel = toNode?.label ?? 'campus destination';
      instructions.add('Continue from $fromLabel to $toLabel');
    }
    instructions.add('Arrive at your destination on the campus path network');
    return instructions;
  }

  double _calculateCampusRouteDistance(LatLng origin, LatLng destination, List<String> pathNodeIds) {
    if (pathNodeIds.isEmpty) {
      return _calculateHaversineDistance(origin, destination);
    }

    var totalDistance = _calculateHaversineDistance(origin, AppConfig.getNodeById(pathNodeIds.first)!.position);
    for (var index = 0; index < pathNodeIds.length - 1; index++) {
      final fromNode = AppConfig.getNodeById(pathNodeIds[index]);
      final toNode = AppConfig.getNodeById(pathNodeIds[index + 1]);
      if (fromNode != null && toNode != null) {
        final edgeDistance = AppConfig.getEdgeDistance(fromNode.id, toNode.id);
        if (edgeDistance != null) {
          totalDistance += edgeDistance;
        } else {
          totalDistance += _calculateHaversineDistance(fromNode.position, toNode.position);
        }
      }
    }
    totalDistance += _calculateHaversineDistance(AppConfig.getNodeById(pathNodeIds.last)!.position, destination);
    return totalDistance;
  }

  List<String> _findShortestPath(String startNodeId, String endNodeId) {
    final distances = <String, double>{startNodeId: 0.0};
    final previous = <String, String>{};
    final unvisited = AppConfig.roadNodes.map((node) => node.id).toList();

    while (unvisited.isNotEmpty) {
      var currentId = unvisited.first;
      var currentDistance = distances[currentId] ?? double.infinity;

      for (final nodeId in unvisited) {
        final nodeDistance = distances[nodeId] ?? double.infinity;
        if (nodeDistance < currentDistance) {
          currentId = nodeId;
          currentDistance = nodeDistance;
        }
      }

      unvisited.remove(currentId);

      if (currentId == endNodeId) {
        return _reconstructPath(previous, currentId);
      }

      if (currentDistance == double.infinity) {
        break;
      }

      final neighbors = AppConfig.getNeighbors(currentId);
      for (final neighborId in neighbors) {
        if (!unvisited.contains(neighborId)) {
          continue;
        }
        final edgeDistance = AppConfig.getEdgeDistance(currentId, neighborId);
        final weight = edgeDistance ?? _calculateHaversineDistance(
          AppConfig.getNodeById(currentId)!.position,
          AppConfig.getNodeById(neighborId)!.position,
        );
        final candidateDistance = currentDistance + weight;
        final existingDistance = distances[neighborId] ?? double.infinity;
        if (candidateDistance < existingDistance) {
          distances[neighborId] = candidateDistance;
          previous[neighborId] = currentId;
        }
      }
    }

    return [];
  }

  List<String> _reconstructPath(Map<String, String> previous, String currentNodeId) {
    final path = <String>[currentNodeId];
    var current = currentNodeId;
    while (previous.containsKey(current)) {
      current = previous[current]!;
      path.insert(0, current);
    }
    return path;
  }

  String? _findClosestNode(LatLng position) {
    String? bestNodeId;
    var bestDistance = double.infinity;

    for (final node in AppConfig.roadNodes) {
      final distance = _calculateHaversineDistance(position, node.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestNodeId = node.id;
      }
    }

    return bestNodeId;
  }

  List<LatLng> _interpolatePointsBetween(LatLng start, LatLng end, {int segments = 3}) {
    final points = <LatLng>[];
    for (var index = 1; index <= segments; index++) {
      final ratio = index / segments;
      points.add(
        LatLng(
          start.latitude + (end.latitude - start.latitude) * ratio,
          start.longitude + (end.longitude - start.longitude) * ratio,
        ),
      );
    }
    return points;
  }

  List<LatLng> _deduplicatePoints(List<LatLng> points) {
    final deduped = <LatLng>[];
    for (final point in points) {
      if (deduped.isEmpty || !_isSamePoint(deduped.last, point)) {
        deduped.add(point);
      }
    }
    return deduped;
  }

  bool _isSamePoint(LatLng first, LatLng second) {
    const tolerance = 1e-8;
    return (first.latitude - second.latitude).abs() < tolerance &&
        (first.longitude - second.longitude).abs() < tolerance;
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